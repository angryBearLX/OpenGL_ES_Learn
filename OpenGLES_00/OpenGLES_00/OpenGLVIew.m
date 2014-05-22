//
//  OpenGLVIew.m
//  OpenGLES_00
//
//  Created by enlifeedward on 14-5-22.
//  Copyright (c) 2014年 enlifeservice. All rights reserved.
//

#import "OpenGLVIew.h"

typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

const Vertex Vertices[] = {
    {{0, 1, 0}, {1, 0, 0, 1}},
    {{-0.5, -1, 0}, {0, 1, 0, 1}},
    {{0.5, -1, 0}, {0, 0, 1, 1}},
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

@implementation OpenGLVIew

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)layoutSubviews
{
    [self setupLayer];
    [self setupContext];
    [self setupColorRenderBuffer];
    [self setupFrameBuffer];
    [self setupShader];
    [self setupVBOs];
    [self render];
}

- (GLuint)getShaderName:(NSString *)shaderName Type:(GLenum)shaderType
{
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [[NSString alloc] initWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Failed to load data from bundle! Error:%@", error);
        exit(1);
    }
    
    const char *shaderCStr = [shaderString UTF8String];
    
    GLuint shaderRef = glCreateShader(shaderType);
    GLint length = [shaderString length];
    glShaderSource(shaderRef, 1, &shaderCStr, &length);
    glCompileShader(shaderRef);
    
    GLint compileSuccess;
    glGetShaderiv(shaderRef, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shaderRef, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageStr);
        exit(1);
    }
    
    return shaderRef;
}

- (void)setupShader
{
    GLuint vertexShader = [self getShaderName:@"VertexShader" Type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self getShaderName:@"FragmentShader" Type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar message[256];
        glGetProgramInfoLog(program, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageStr);
        exit(1);
    }
    
    glUseProgram(program);
    
    _positionSlot = glGetAttribLocation(program, "Position");
    _colorSlot = glGetAttribLocation(program, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
}

// 1
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

// 2
- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer *)self.layer;
    //设置不透明
    _eaglLayer.opaque = NO;
    
    //kEAGLDrawablePropertyRetainedBacking 设定渲染后是否保存渲染内容，默认是不保存，布尔值NO
    //kEAGLDrawablePropertyColorFormat 设定渲染像素格式，默认是kEAGLColorFormatRGBA8
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

// 3
- (void)setupContext
{
    //设置ES2.0 的api为上下文
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_eaglContext) {
        NSLog(@"Failed to create EAGLContext!");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:_eaglContext]) {
        NSLog(@"Failed to set current EAGLContext!");
        exit(1);
    }
}

// 4
- (void)setupColorRenderBuffer
{
    //分配一个颜色缓冲区id
    glGenRenderbuffers(1, &_colorRenderBuffer);
    //绑定到当前的渲染缓冲区里
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    //分配空间给渲染缓冲区
    [_eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

// 5
- (void)setupFrameBuffer
{
    //分配一个帧缓冲区ID
    glGenFramebuffers(1, &_frameBuffer);
    //绑定到当前的帧缓冲区上面
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    //将_colorRenderBuffer附着在GL_FRAMEBUFFER的GL_COLOR_ATTACHMENT0点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
}

- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}

// 6
- (void)render
{
    //以rgba为颜色清楚背景色
    glClearColor(0.7, 0.7, 0.7, 1);
    //清除颜色缓冲区内容
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    // 3
//    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]),
//                   GL_UNSIGNED_BYTE, 0);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    [_eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

@end
