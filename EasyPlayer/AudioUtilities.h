
static void CheckError(OSStatus error, const char *operation) {
	if (error == noErr) return;
	char errorString[20];
	// See if it appears to be a 4-char-code
	*(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
	if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) { errorString[0] = errorString[5] = '\''; errorString[6] = '\0';
	} else {
		// No, format it as an integer
		sprintf(errorString, "%d", (int)error);
	}
	fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
	assert(error == noErr);
}

static AudioStreamBasicDescription LPCMStreamDescription()
{
//    AudioStreamBasicDescription destFormat;
//    bzero(&destFormat, sizeof(AudioStreamBasicDescription));
//    destFormat.mSampleRate = 44100.0;
//    destFormat.mFormatID = kAudioFormatLinearPCM;
//    destFormat.mReserved = 0;
//    destFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat;
//    destFormat.mBitsPerChannel = sizeof(Float32) * 8;
//    destFormat.mChannelsPerFrame = 1;
//    destFormat.mBytesPerFrame = destFormat.mChannelsPerFrame * sizeof(Float32);
//    destFormat.mFramesPerPacket = 1;
//    destFormat.mBytesPerPacket = destFormat.mFramesPerPacket * destFormat.mBytesPerFrame;
//    return destFormat;
    AudioStreamBasicDescription destFormat;
    bzero(&destFormat, sizeof(AudioStreamBasicDescription));
    destFormat.mSampleRate = 44100.0;
    destFormat.mFormatID = kAudioFormatLinearPCM;
    destFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    
    destFormat.mFramesPerPacket = 1;
    destFormat.mBytesPerPacket = 4;
    destFormat.mBytesPerFrame = 4;
    destFormat.mChannelsPerFrame = 2;
    destFormat.mBitsPerChannel = 16;
    destFormat.mReserved = 0;
    return destFormat;
}