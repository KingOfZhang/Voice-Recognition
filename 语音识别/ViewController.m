//
//  ViewController.m
//  语音识别
//
//  Created by 易云时代 on 2017/6/27.
//  Copyright © 2017年 笑伟. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<SFSpeechRecognizerDelegate>
@property (strong, nonatomic) UIButton *siriBtu;//siri按钮
@property (strong, nonatomic) UITextView *siriTextView; //显示语音转化成的文本
@property (strong, nonatomic) SFSpeechRecognitionTask *recognitionTask; //语音识别任务
@property (strong, nonatomic)SFSpeechRecognizer *speechRecognizer; //语音识别器
@property (strong, nonatomic) SFSpeechAudioBufferRecognitionRequest *recognitionRequest; //识别请求
@property (strong, nonatomic)AVAudioEngine *audioEngine; //录音引擎
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.siriBtu = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
    self.siriBtu.backgroundColor = [UIColor redColor];
    [self.siriBtu addTarget:self action:@selector(microphoneTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.siriBtu];
    _siriTextView = [[UITextView alloc]initWithFrame:CGRectMake(0, 230, 200, 200)];
    [self.view addSubview:_siriTextView];
    
    //设备识别语言为中文
    NSLocale *cale = [[NSLocale alloc]initWithLocaleIdentifier:@"zh-CN"];
    self.speechRecognizer = [[SFSpeechRecognizer alloc]initWithLocale:cale];
    self.siriBtu.enabled = false;
    
    //设置代理
    _speechRecognizer.delegate = self;
    
    //发送语音认证请求(首先要判断设备是否支持语音识别功能)
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        bool isButtonEnabled = false;
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                isButtonEnabled = true;
                NSLog(@"可以语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                isButtonEnabled = false;
                NSLog(@"用户被拒绝访问语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                isButtonEnabled = false;
                NSLog(@"不能在该设备上进行语音识别");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                isButtonEnabled = false;
                NSLog(@"没有授权语音识别");
                break;
            default:
                break;
        }
        self.siriBtu.enabled = isButtonEnabled;
    }];
    
    //创建录音引擎
    self.audioEngine = [[AVAudioEngine alloc]init];
}
- (void)microphoneTap:(UIButton *)sender {
    if ([self.audioEngine isRunning]) {
        [self.audioEngine stop];
        [self.recognitionRequest endAudio];
        self.siriBtu.enabled = YES;
        [self.siriBtu setTitle:@"开始录制" forState:UIControlStateNormal];
    }else{
        [self startRecording];
        [self.siriBtu setTitle:@"停止录制" forState:UIControlStateNormal];
    }
}
-(void)startRecording{
    if (self.recognitionTask) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    bool  audioBool = [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    bool  audioBool1= [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
    bool  audioBool2= [audioSession setActive:true withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (audioBool || audioBool1||  audioBool2) {
        NSLog(@"可以使用");
    }else{
        NSLog(@"这里说明有的功能不支持");
    }
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc]init];
    recognitionRequest.shouldReportPartialResults = YES;
    self.recognitionRequest.shouldReportPartialResults = true;
    
    //开始识别任务
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        bool isFinal = false;
        if (result) {
            self.siriTextView.text = [[result bestTranscription] formattedString]; //语音转文本
            isFinal = [result isFinal];
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            self.recognitionRequest = nil;
            self.recognitionTask = nil;
            self.siriBtu.enabled = true;
        }
    }];
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [self.audioEngine prepare];
    bool audioEngineBool = [self.audioEngine startAndReturnError:nil];
    NSLog(@"%d",audioEngineBool);
    self.siriTextView.text = @"请说话";
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if(available){
        self.siriBtu.enabled = true;
    }else{
        self.siriBtu.enabled = false;
    }
}

@end
