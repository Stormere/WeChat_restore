//
//  PCMPlayer.m
//  play_pcm
//
//  Created by 郜俊博 on 2018/6/26.
//  Copyright © 2018年 郜俊博. All rights reserved.
//

#import "PCMPlayer.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <pthread.h>

#include "SKP_Silk_SDK_API.h"
#include "SKP_Silk_SigProc_FIX.h"

#define MAX_BYTES_PER_FRAME     1024
#define MAX_INPUT_FRAMES        5
#define MAX_FRAME_LENGTH        480
#define FRAME_LENGTH_MS         20
#define MAX_API_FS_KHZ          48
#define MAX_LBRR_DELAY          2

/* Seed for the random number generator, which is used for simulating packet loss */
static SKP_int32 rand_seed = 1;

#define MIN_SIZE_PER_FRAME 1024*1024
#define QUEUE_BUFFER_SIZE 3      //队列缓冲个数

//一次播放的buffer的长度
#define PLAY_SIZE                (2048*sizeof(SKP_int16))

//播放的缓冲区
char *play_buffer = NULL;
char *play_buffer_start = NULL;
//dispatch_semaphore_t play_event ; //提交验证码的信号量
//dispatch_semaphore_t decode_event ; //提交验证码的信号量

static PCMPlayer *selfClass =nil;



@interface PCMPlayer() {
    
    AudioQueueRef audioQueue;                                 //音频播放队列
    AudioStreamBasicDescription _audioDescription;
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; //音频缓存
    BOOL audioQueueBufferUsed[QUEUE_BUFFER_SIZE];             //判断音频缓存是否在使用
    NSLock *sysnLock;
    NSMutableData *tempData;
    OSStatus osState;
    
    
}
@end

@interface PCMPlayer()

@property  (strong) dispatch_semaphore_t play_event ; //提交验证码的信号量
@property  (strong) dispatch_semaphore_t decode_event ; //提交验证码的信号量



@end

@implementation PCMPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        selfClass = self;
        sysnLock = [[NSLock alloc]init];
//        play_event = nil;
//        decode_event = nil;
        _play_event = dispatch_semaphore_create(0);
        _decode_event = dispatch_semaphore_create(0);

        // 播放PCM使用
        if (_audioDescription.mSampleRate <= 0) {
            //设置音频参数
            _audioDescription.mSampleRate = 24000.0;//采样率
            _audioDescription.mFormatID = kAudioFormatLinearPCM;
            // 下面这个是保存音频数据的方式的说明，如可以根据大端字节序或小端字节序，浮点数或整数以及不同体位去保存数据
            _audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
            //1单声道 2双声道
            _audioDescription.mChannelsPerFrame = 1;
            //每一个packet一侦数据,每个数据包下的桢数，即每个数据包里面有多少桢
            _audioDescription.mFramesPerPacket = 1;
            //每个采样点16bit量化 语音每采样点占用位数
            _audioDescription.mBitsPerChannel = 16;
            _audioDescription.mBytesPerFrame = (_audioDescription.mBitsPerChannel / 8) * _audioDescription.mChannelsPerFrame;
            //每个数据包的bytes总数，每桢的bytes数*每个数据包的桢数
            _audioDescription.mBytesPerPacket = _audioDescription.mBytesPerFrame * _audioDescription.mFramesPerPacket;
        }
        
        // 使用player的内部线程播放 新建输出
        AudioQueueNewOutput(&_audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, 0, 0, &audioQueue);
        
        // 设置音量
        AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 3.0);
        
        // 初始化需要的缓冲区
        for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
            audioQueueBufferUsed[i] = false;
            
            osState = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);
            
            printf("第 %d 个AudioQueueAllocateBuffer 初始化结果 %d (0表示成功)", i + 1, osState);
        }
        
        osState = AudioQueueStart(audioQueue, NULL);
        if (osState != noErr) {
            printf("AudioQueueStart Error");
        }
    }
    return self;
}

- (void)resetPlay {
    if (audioQueue != nil) {
        AudioQueueReset(audioQueue);
    }
}
// 播放相关
-(void)playWithData:(NSData *)data {
    
    [sysnLock lock];
    
    tempData = [NSMutableData new];
    [tempData appendData: data];
    // 得到数据
    NSUInteger len = tempData.length;
    Byte *bytes = (Byte*)malloc(len);
    [tempData getBytes:bytes length: len];
    
    int i = 0;
    while (true) {
        if (!audioQueueBufferUsed[i]) {
            audioQueueBufferUsed[i] = true;
            break;
        }else {
            i++;
            if (i >= QUEUE_BUFFER_SIZE) {
                i = 0;
            }
        }
    }
    
    audioQueueBuffers[i] -> mAudioDataByteSize =  (unsigned int)len;
    // 把bytes的头地址开始的len字节给mAudioData
    NSLog(@"%p",audioQueueBuffers[i] -> mAudioData);
    memcpy(audioQueueBuffers[i] -> mAudioData, bytes, len);
    
    //
    free(bytes);
    // bytes = NULL;
    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffers[i], 0, NULL);
    
    printf("本次播放数据大小: %lu", len);
    [sysnLock unlock];
}


unsigned long GetHighResolutionTime() /* O: time in usec*/
{
    struct timeval tv;
    gettimeofday(&tv, 0);
    return((tv.tv_sec * 1000000) + (tv.tv_usec));
}




void *play_stream_data(void *pParam)
{
    while (1)
    {
        dispatch_semaphore_wait(selfClass.play_event,DISPATCH_TIME_FOREVER);
        //[selfClass playWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"aud"]]];
        [selfClass playWithData:[NSData dataWithBytes:play_buffer_start length:(play_buffer-play_buffer_start)]];
        dispatch_semaphore_signal(selfClass.decode_event);

        
    }
}

-(void)playWithPath:( char *)srcFile info:(int )verbose API_Fs_Hz:(int ) API_Fs_Hz{
    
    play_buffer = (char *)malloc(PLAY_SIZE);
    memset(play_buffer, 0, PLAY_SIZE);
    play_buffer_start = play_buffer;
    
    unsigned long tottime, starttime;
    double    filetime;
    size_t    counter;
    SKP_int32 totPackets, i, k;
    SKP_int16 ret, len, tot_len;
    SKP_int16 nBytes;
    SKP_uint8 payload[MAX_BYTES_PER_FRAME * MAX_INPUT_FRAMES * (MAX_LBRR_DELAY + 1)];
    SKP_uint8 *payloadEnd = NULL, *payloadToDec = NULL;
    SKP_uint8 FECpayload[MAX_BYTES_PER_FRAME * MAX_INPUT_FRAMES], *payloadPtr;
    SKP_int16 nBytesFEC;
    SKP_int16 nBytesPerPacket[MAX_LBRR_DELAY + 1], totBytes;
    SKP_int16 out[((FRAME_LENGTH_MS * MAX_API_FS_KHZ) << 1) * MAX_INPUT_FRAMES], *outPtr;
    FILE      *bitInFile;
    SKP_int32 packetSize_ms = 0;
    SKP_int32 decSizeBytes;
    void      *psDec;
    SKP_float loss_prob;
    SKP_int32 frames, lost;
    
    SKP_SILK_SDK_DecControlStruct DecControl;
    if (verbose != 0) {
        printf("********** Silk Decoder (Fixed Point) v %s ********************\n", SKP_Silk_SDK_get_version());
        printf("********** Compiled for %d bit cpu *******************************\n", (int)sizeof(void*) * 8);
        printf("Input:                       %s\n", srcFile);
    }
    bitInFile = fopen(srcFile, "rb");
    if (bitInFile == NULL)
    {
        printf("Error: could not open input file %s\n", srcFile);
        return;
    }
    /* default settings */
    loss_prob = 0.0f;
    /* Check Silk header */
    {
        char header_buf[50];
        counter = fread(header_buf, sizeof(char), strlen("#!SILK_V3") + 1, bitInFile);
        header_buf[strlen("#!SILK_V3") + 1] = '\0'; /* Terminate with a null character */
        if (strcmp(header_buf, "\x2#!SILK_V3") != 0) {
            /* Non-equal strings */
            printf("Error: Wrong Header %s\n", header_buf);
            return;
        }
    }
    
    pthread_t tid;
    int error = pthread_create(&tid, NULL, play_stream_data, NULL);
    if (error != 0) {
        printf("%s\n","can't create thread!");
    }
    /* Set the samplingrate that is requested for the output */
    if (API_Fs_Hz == 0) {
        DecControl.API_sampleRate = 24000;
    }
    else {
        DecControl.API_sampleRate = API_Fs_Hz;
    }
    /* Initialize to one frame per packet, for proper concealment before first packet arrives */
    DecControl.framesPerPacket = 1;
    /* Create decoder */
    ret = SKP_Silk_SDK_Get_Decoder_Size(&decSizeBytes);
    if (ret) {
        printf("\nSKP_Silk_SDK_Get_Decoder_Size returned %d", ret);
    }
    psDec = malloc(decSizeBytes);
    /* Reset decoder */
    ret = SKP_Silk_SDK_InitDecoder(psDec);
    if (ret) {
        printf("\nSKP_Silk_InitDecoder returned %d", ret);
    }
    totPackets = 0;
    tottime = 0;
    payloadEnd = payload;
    /* Simulate the jitter buffer holding MAX_FEC_DELAY packets */
    for (i = 0; i < MAX_LBRR_DELAY; i++) {
        /* Read payload size */
        counter = fread(&nBytes, sizeof(SKP_int16), 1, bitInFile);
#ifdef _SYSTEM_IS_BIG_ENDIAN
        swap_endian(&nBytes, 1);
#endif
        /* Read payload */
        counter = fread(payloadEnd, sizeof(SKP_uint8), nBytes, bitInFile);
        if ((SKP_int16)counter < nBytes) {
            break;
        }
        nBytesPerPacket[i] = nBytes;
        payloadEnd += nBytes;
        totPackets++;
    }
    
    long pack_length = 0;// 已经解码的数据的长度
    
    while (1) {
        /* Read payload size */
        counter = fread(&nBytes, sizeof(SKP_int16), 1, bitInFile);
#ifdef _SYSTEM_IS_BIG_ENDIAN
        swap_endian(&nBytes, 1);
#endif
        if (nBytes < 0 || counter < 1) {
            break;
        }
        /* Read payload */
        counter = fread(payloadEnd, sizeof(SKP_uint8), nBytes, bitInFile);
        if ((SKP_int16)counter < nBytes) {
            break;
        }
        /* Simulate losses */
        rand_seed = SKP_RAND(rand_seed);
        if ((((float)((rand_seed >> 16) + (1 << 15))) / 65535.0f >= (loss_prob / 100.0f)) && (counter > 0)) {
            nBytesPerPacket[MAX_LBRR_DELAY] = nBytes;
            payloadEnd += nBytes;
        }
        else {
            nBytesPerPacket[MAX_LBRR_DELAY] = 0;
        }
        if (nBytesPerPacket[0] == 0) {
            /* Indicate lost packet */
            lost = 1;
            /* Packet loss. Search after FEC in next packets. Should be done in the jitter buffer */
            payloadPtr = payload;
            for (i = 0; i < MAX_LBRR_DELAY; i++) {
                if (nBytesPerPacket[i + 1] > 0) {
                    starttime = GetHighResolutionTime();
                    SKP_Silk_SDK_search_for_LBRR(payloadPtr, nBytesPerPacket[i + 1], (i + 1), FECpayload, &nBytesFEC);
                    tottime += GetHighResolutionTime() - starttime;
                    if (nBytesFEC > 0) {
                        payloadToDec = FECpayload;
                        nBytes = nBytesFEC;
                        lost = 0;
                        break;
                    }
                }
                payloadPtr += nBytesPerPacket[i + 1];
            }
        }
        else {
            lost = 0;
            nBytes = nBytesPerPacket[0];
            payloadToDec = payload;
        }
        /* Silk decoder */
        outPtr = out;
        tot_len = 0;
        starttime = GetHighResolutionTime();
        if (lost == 0) {
            /* No Loss: Decode all frames in the packet */
            frames = 0;
            do {
                /* Decode 20 ms */
                ret = SKP_Silk_SDK_Decode(psDec, &DecControl, 0, payloadToDec, nBytes, outPtr, &len);
                if (ret) {
                    printf("\nSKP_Silk_SDK_Decode returned %d", ret);
                }
                frames++;
                outPtr += len;
                tot_len += len;
                if (frames > MAX_INPUT_FRAMES) {
                    /* Hack for corrupt stream that could generate too many frames */
                    outPtr = out;
                    tot_len = 0;
                    frames = 0;
                }
                /* Until last 20 ms frame of packet has been decoded */
            } while (DecControl.moreInternalDecoderFrames);
        }
        else {
            /* Loss: Decode enough frames to cover one packet duration */
            for (i = 0; i < DecControl.framesPerPacket; i++) {
                /* Generate 20 ms */
                ret = SKP_Silk_SDK_Decode(psDec, &DecControl, 1, payloadToDec, nBytes, outPtr, &len);
                if (ret) {
                    printf("\nSKP_Silk_Decode returned %d", ret);
                }
                outPtr += len;
                tot_len += len;
            }
        }
        packetSize_ms = tot_len / (DecControl.API_sampleRate / 1000);
        tottime += GetHighResolutionTime() - starttime;
        totPackets++;
        /* Write output to file */
#ifdef _SYSTEM_IS_BIG_ENDIAN
        swap_endian(out, tot_len);
#endif
        // fwrite(out, sizeof(SKP_int16), tot_len, speechOutFile);
        pack_length += sizeof(SKP_int16) * tot_len;
        if (pack_length > PLAY_SIZE / 2)
        {
            dispatch_semaphore_signal(selfClass.play_event);
            dispatch_semaphore_wait(selfClass.decode_event,DISPATCH_TIME_FOREVER);
            pack_length = 0;
            play_buffer = play_buffer_start;
        }
        memcpy(play_buffer, out, sizeof(SKP_int16) * tot_len);
        play_buffer += sizeof(SKP_int16) * tot_len;
        
        /* Update buffer */
        totBytes = 0;
        for (i = 0; i < MAX_LBRR_DELAY; i++) {
            totBytes += nBytesPerPacket[i + 1];
        }
        SKP_memmove(payload, &payload[nBytesPerPacket[0]], totBytes * sizeof(SKP_uint8));
        payloadEnd -= nBytesPerPacket[0];
        SKP_memmove(nBytesPerPacket, &nBytesPerPacket[1], MAX_LBRR_DELAY * sizeof(SKP_int16));
        if (verbose != 0) {
            fprintf(stderr, "\rPackets decoded:             %d\n", totPackets);
        }
    }
    /* Empty the recieve buffer */
    for (k = 0; k < MAX_LBRR_DELAY; k++) {
        if (nBytesPerPacket[0] == 0) {
            /* Indicate lost packet */
            lost = 1;
            /* Packet loss. Search after FEC in next packets. Should be done in the jitter buffer */
            payloadPtr = payload;
            for (i = 0; i < MAX_LBRR_DELAY; i++) {
                if (nBytesPerPacket[i + 1] > 0) {
                    starttime = GetHighResolutionTime();
                    SKP_Silk_SDK_search_for_LBRR(payloadPtr, nBytesPerPacket[i + 1], (i + 1), FECpayload, &nBytesFEC);
                    tottime += GetHighResolutionTime() - starttime;
                    if (nBytesFEC > 0) {
                        payloadToDec = FECpayload;
                        nBytes = nBytesFEC;
                        lost = 0;
                        break;
                    }
                }
                payloadPtr += nBytesPerPacket[i + 1];
            }
        }
        else {
            lost = 0;
            nBytes = nBytesPerPacket[0];
            payloadToDec = payload;
        }
        /* Silk decoder */
        outPtr = out;
        tot_len = 0;
        starttime = GetHighResolutionTime();
        if (lost == 0) {
            /* No loss: Decode all frames in the packet */
            frames = 0;
            do {
                /* Decode 20 ms */
                ret = SKP_Silk_SDK_Decode(psDec, &DecControl, 0, payloadToDec, nBytes, outPtr, &len);
                if (ret) {
                    printf("\nSKP_Silk_SDK_Decode returned %d", ret);
                }
                frames++;
                outPtr += len;
                tot_len += len;
                if (frames > MAX_INPUT_FRAMES) {
                    /* Hack for corrupt stream that could generate too many frames */
                    outPtr = out;
                    tot_len = 0;
                    frames = 0;
                }
                /* Until last 20 ms frame of packet has been decoded */
            } while (DecControl.moreInternalDecoderFrames);
        }
        else {
            /* Loss: Decode enough frames to cover one packet duration */
            /* Generate 20 ms */
            for (i = 0; i < DecControl.framesPerPacket; i++) {
                ret = SKP_Silk_SDK_Decode(psDec, &DecControl, 1, payloadToDec, nBytes, outPtr, &len);
                if (ret) {
                    printf("\nSKP_Silk_Decode returned %d", ret);
                }
                outPtr += len;
                tot_len += len;
            }
        }
        packetSize_ms = tot_len / (DecControl.API_sampleRate / 1000);
        tottime += GetHighResolutionTime() - starttime;
        totPackets++;
        /* Write output to file */
#ifdef _SYSTEM_IS_BIG_ENDIAN
        swap_endian(out, tot_len);
#endif
        // fwrite(out, sizeof(SKP_int16), tot_len, speechOutFile);
        pack_length += sizeof(SKP_int16) * tot_len;
        if (pack_length > PLAY_SIZE / 2)
        {
            dispatch_semaphore_signal(selfClass.play_event);
            dispatch_semaphore_wait(selfClass.decode_event,DISPATCH_TIME_FOREVER);
            pack_length = 0;
            play_buffer = play_buffer_start;
        }
        memcpy(play_buffer, out, sizeof(SKP_int16) * tot_len);
        play_buffer += sizeof(SKP_int16) * tot_len;
        
        /* Update Buffer */
        totBytes = 0;
        for (i = 0; i < MAX_LBRR_DELAY; i++) {
            totBytes += nBytesPerPacket[i + 1];
        }
        SKP_memmove(payload, &payload[nBytesPerPacket[0]], totBytes * sizeof(SKP_uint8));
        payloadEnd -= nBytesPerPacket[0];
        SKP_memmove(nBytesPerPacket, &nBytesPerPacket[1], MAX_LBRR_DELAY * sizeof(SKP_int16));
        if (verbose != 0) {
            fprintf(stderr, "\rPackets decoded:              %d", totPackets);
        }
    }
    dispatch_semaphore_signal(selfClass.play_event);
    dispatch_semaphore_wait(selfClass.decode_event,DISPATCH_TIME_FOREVER);
    
//    SetEvent(play_event);//播放
//    WaitForSingleObject(decode_event, INFINITE);
//    ResetEvent(decode_event);
//    TerminateThread(play_thread, 0);
//    CloseHandle(play_thread);
//    CloseHandle(play_event);
//    CloseHandle(decode_event);
    /* Free decoder */
    free(psDec);
    /* Close files */
    fclose(bitInFile);
    filetime = totPackets * 1e-3 * packetSize_ms;
    if (verbose != 0) {
        printf("\nFile length:                 %.3f s", filetime);
        printf("\nTime for decoding:           %.3f s (%.3f%% of realtime)", 1e-6 * tottime, 1e-4 * tottime / filetime);
        printf("\n\n");
    }
    else {
        /* print time and % of realtime */
        printf("%.3f %.3f %d\n", 1e-6 * tottime, 1e-4 * tottime / filetime, totPackets);
    }
    play_buffer = play_buffer_start;
    play_buffer_start = NULL;
    free(play_buffer);
}
#ifdef AAA
/* Function to convert a little endian int16 to a */
/* big endian int16 or vica verca                 */
void swap_endian(
                 SKP_int16       vec[],
                 SKP_int         len
                 )
{
    SKP_int i;
    SKP_int16 tmp;
    SKP_uint8 *p1, *p2;
    for (i = 0; i < len; i++) {
        tmp = vec[i];
        p1 = (SKP_uint8 *)&vec[i]; p2 = (SKP_uint8 *)&tmp;
        p1[0] = p2[1]; p1[1] = p2[0];
    }
}
#endif



// ************************** 回调 **********************************

// 回调回来把buffer状态设为未使用
static void AudioPlayerAQInputCallback(void* inUserData,AudioQueueRef audioQueueRef, AudioQueueBufferRef audioQueueBufferRef) {
    
    PCMPlayer* player = (__bridge PCMPlayer*)inUserData;
    
    
    [player resetBufferState:audioQueueRef and:audioQueueBufferRef];
}

- (void)resetBufferState:(AudioQueueRef)audioQueueRef and:(AudioQueueBufferRef)audioQueueBufferRef {
    
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        // 将这个buffer设为未使用
        if (audioQueueBufferRef == audioQueueBuffers[i]) {
            audioQueueBufferUsed[i] = false;
        }
    }
}

// ************************** 内存回收 **********************************

- (void)dealloc {
    
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue,true);
    }
    
    audioQueue = nil;
    sysnLock = nil;
}

@end
