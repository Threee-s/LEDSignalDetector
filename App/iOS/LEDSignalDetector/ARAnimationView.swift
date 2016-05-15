//
//  ARAnimationView.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/05/10.
//  Copyright © 2016年 TrE. All rights reserved.
//

import Foundation
import UIKit
import OpenGLES

class ARAnimationView: UIView {

    private var context: EAGLContext?
    private var viewFramebuffer = GLuint()
    private var viewRenderbuffer = GLuint()
    
    
    override class func layerClass() -> AnyClass {
        return CAEAGLLayer.self
    }
    
    
    override init (frame: CGRect) {
        
        super.init(frame: frame)
        
        let eaglLayer: CAEAGLLayer = self.layer as! CAEAGLLayer
        eaglLayer.opaque = true
        eaglLayer.drawableProperties = [
            kEAGLDrawablePropertyRetainedBacking: false,
            kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8
            ] as NSDictionary as [NSObject : AnyObject]
        
        //コンテキストの生成。
        context = EAGLContext(API: EAGLRenderingAPI.OpenGLES3)
        
        //対象のコンテキストを「現在の」コンテキストとして設定
        EAGLContext.setCurrentContext(context)
        
        //フレームバッファを生成。そのIDをviewFramebufferに代入してもらう
        glGenFramebuffersOES(1, &viewFramebuffer)
        //対象のフレームバッファを「現在の」フレームバッファとして設定
        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), viewFramebuffer)
        
        //レンダーバッファを生成。そのIDをviewRenderbufferに代入してもらう
        glGenRenderbuffersOES(1, &viewRenderbuffer)
        //対象のレンダーバッファを「現在の」レンダーバッファとして設定
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)
        
        //フレームバッファにレンダーバッファを、カラーバッファとしてアタッチ
        glFramebufferRenderbufferOES(GLenum(GL_FRAMEBUFFER_OES), GLenum(GL_COLOR_ATTACHMENT0_OES), GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)
        
        //レンダーバッファオブジェクトに、描画可能なオブジェクトのストレージをバインド
        self.context!.renderbufferStorage(Int(GL_RENDERBUFFER_OES), fromDrawable:eaglLayer)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        
        let width = self.bounds.size.width
        let height = self.bounds.size.height
        
        //ビューポートの設定
        glViewport(0, 0, GLsizei(width), GLsizei(height));
        
        self.render()
    }
    
    /**
     * 明示的な再描画したいタイミング、もしくはこのViewのサイズが変更されるなどで
     * layoutSubviewsが実行される時に、実行される予定。
     */
    func render() {
        
        //先ほどのコンテキストを「現在の」コンテキストとして設定
        EAGLContext.setCurrentContext(context)
        
        //対象のフレームバッファを「現在の」フレームバッファとして設定
        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), GLenum(viewFramebuffer))
        
        //クリアする色を設定
        glClearColor(0.0, 0.0, 0.0, 0.0)
        //描画領域全体をクリア
        glClear(GLenum(GL_COLOR_BUFFER_BIT))
        
        //**********************
        //ここに描画したい内容を書く
        //**********************
        
        //対象のレンダーバッファを「現在の」レンダーバッファとして設定
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)
        
        //レンダバッファを画面に表示
        self.context?.presentRenderbuffer(Int(GL_RENDERBUFFER_OES))
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
