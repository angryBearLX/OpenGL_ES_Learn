//
//  OpenGLVIew.h
//  OpenGLES_00
//
//  Created by enlifeedward on 14-5-22.
//  Copyright (c) 2014年 enlifeservice. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
//添加OpenGL ES框架，这里先使用ES2版本
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface OpenGLVIew : UIView
{
    //渲染主体层,渲染操作在改layer上进行
    CAEAGLLayer *_eaglLayer;
    
    //opengl上下文
    EAGLContext *_eaglContext;
    
    //颜色渲染缓冲区
    GLuint _colorRenderBuffer;
    //帧渲染缓冲区
    GLuint _frameBuffer;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
}



@end
