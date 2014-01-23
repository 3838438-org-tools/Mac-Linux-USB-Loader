//
//  SBPersistenceManagerWindowController.m
//  Mac Linux USB Loader
//
//  Created by SevenBits on 1/22/14.
//  Copyright (c) 2014 SevenBits. All rights reserved.
//

#import "SBPersistenceManagerWindowController.h"
#import "SBAppDelegate.h"
#import "SBUSBDevice.h"

@interface SBPersistenceManagerWindowController ()

@end

@implementation SBPersistenceManagerWindowController {
	NSMutableDictionary *dict;
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

	// Hide the setup view until we need it.
	[self.persistenceOptionsSetupBox setHidden:YES];
    
    // Setup the USB selector.
	dict = [NSMutableDictionary dictionaryWithDictionary:[[NSApp delegate] usbDictionary]];
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[dict count]];

	for (NSString *usb in dict) {
		[array insertObject:[dict[usb] name] atIndex:0];
	}

    [self.popupValues addObjects:array];

	[self.usbSelectorPopup addItemWithObjectValue:@"---"];
	[self.usbSelectorPopup setStringValue:@"---"];
	[self.usbSelectorPopup addItemsWithObjectValues:array];
	[self.usbSelectorPopup setDelegate:self];

	[self.persistenceVolumeSizeTextField setDelegate:self];
	[self.persistenceVolumeSizeSlider bind:@"value"
								  toObject:self.persistenceVolumeSizeTextField
							   withKeyPath:@"integerValue" options:nil];
}

- (void)controlTextDidChange:(NSNotification *)note {
	[self.persistenceVolumeSizeSlider setIntegerValue:[self.persistenceVolumeSizeTextField integerValue]];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification {
	if ([self.usbSelectorPopup indexOfSelectedItem] != 0) {
		[self.persistenceOptionsSetupBox setHidden:NO];
	} else {
		[self.persistenceOptionsSetupBox setHidden:YES];
	}
}

- (IBAction)createPersistenceButtonPressed:(id)sender {
	// Disable all buttons.
	[sender setEnabled:NO];
	[self.persistenceVolumeSizeSlider setEnabled:NO];
	[self.persistenceVolumeSizeTextField setEnabled:NO];
	[self.usbSelectorPopup setEnabled:NO];

	// Create an NSTask object.
	NSTask *task = [[NSTask alloc] init];

	NSString *selectedUSB = [self.usbSelectorPopup objectValueOfSelectedItem];
	NSString *persistenceFilePath = [NSString stringWithFormat:@"%@",
									 [[dict[selectedUSB] path] stringByAppendingString:@"/casper-rw"]];

	NSInteger persistenceSizeInBytes = [self.persistenceVolumeSizeSlider integerValue] / 1048576;

	NSSavePanel *spanel = [NSSavePanel savePanel];
	[spanel setMessage:NSLocalizedString(@"You must authorize file creation on this USB. Click Save below.", nil)];
	[spanel setDirectoryURL:[NSURL URLWithString:[dict[selectedUSB] path]]];
	[spanel setNameFieldStringValue:@"casper-rw"];
    [spanel setCanCreateDirectories:NO];
    [spanel setCanSelectHiddenExtension:YES];
    [spanel setTreatsFilePackagesAsDirectories:YES];
    [spanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
         if (result == NSFileHandlingPanelOKButton) {
             NSURL *saveURL = [spanel URL];
             NSLog(@"%@", saveURL);

			 // Initalize the NSTask.
			 task.launchPath = @"/bin/dd";
			 task.arguments = @[@"if=/dev/zero", [@"of=" stringByAppendingString:persistenceFilePath], @"bs=1m",
								[NSString stringWithFormat:@"count=%ld", (long)persistenceSizeInBytes]];
			 NSLog(@"%@", [task.arguments componentsJoinedByString:@" "]);

			 // Launch the NSTask.
			 [task launch];

			 // Wait for the operation to complete on another thread.
			 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				 [task waitUntilExit];
				 dispatch_async(dispatch_get_main_queue(), ^{
					 NSLog(@"Done!");

					 // Enable the disabled elements.
					 [sender setEnabled:YES];
					 [self.persistenceVolumeSizeSlider setEnabled:YES];
					 [self.persistenceVolumeSizeTextField setEnabled:YES];
					 [self.usbSelectorPopup setEnabled:YES];
				 });
			 });
         } else {
			 // Enable the disabled elements.
			 [sender setEnabled:YES];
			 [self.persistenceVolumeSizeSlider setEnabled:YES];
			 [self.persistenceVolumeSizeTextField setEnabled:YES];
			 [self.usbSelectorPopup setEnabled:YES];
		 }
     }];
}

@end
