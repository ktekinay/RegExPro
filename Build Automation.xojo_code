#tag BuildAutomation
			Begin BuildStepList Linux
				Begin BuildProjectStep Build
				End
			End
			Begin BuildStepList Mac OS X
				Begin BuildProjectStep Build
				End
				Begin CopyFilesBuildStep CopyPCREMacIntel
					AppliesTo = 0
					Architecture = 1
					Destination = 2
					Subdirectory = 
					FolderItem = Li4vUENSRSUyMExpYnMvTWFjJTIwSW50ZWwvcGNyZV9saWJzLw==
				End
			End
			Begin BuildStepList Windows
				Begin BuildProjectStep Build
				End
			End
#tag EndBuildAutomation
