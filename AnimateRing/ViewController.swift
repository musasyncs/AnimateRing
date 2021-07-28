//
//  ViewController.swift
//  AnimateRing
//
//  Created by Ewen on 2021/7/27.
//

import UIKit

class ViewController: UIViewController, URLSessionDownloadDelegate {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var pulsatingLayer: CAShapeLayer!
    
    var runningLayer: CAShapeLayer!
    
    //下載進度百分比標籤
    private let percentageLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        label.textAlignment = .center
        label.text = "0%"
        label.font = UIFont.systemFont(ofSize: 30, weight: .light)
        label.textColor = UIColor.myLabelColor
        return label
    }()
    
    //下載按鈕
    private let downloadButton: UIButton = {
        let button = UIButton()
        button.setTitle("Download", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        button.tintColor = UIColor.myLabelColor
        button.backgroundColor = UIColor.myBurttonColor
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()

    //個別占比標籤
    private func createDonutLabel(percentage: CGFloat, startDegree: CGFloat, labelRadius: CGFloat, labelCenter: CGPoint) -> UILabel {
        let textCenterDegree = startDegree + 360 * percentage / 100 / 2
        
        //只是為了標一個點
        let textPath = UIBezierPath(arcCenter: labelCenter,
                                    radius: labelRadius,
                                    startAngle: CGFloat.pi / 180  * textCenterDegree,
                                    endAngle: CGFloat.pi / 180  * textCenterDegree,
                                    clockwise: true)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
        label.center = textPath.currentPoint
        label.textAlignment = .center
        label.text = "\(percentage)%"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.backgroundColor
        return label
    }
    
    //圓環layer（pulsating/track/running layer）
    private func createRingLayer(strokeColor: UIColor, fillColor: UIColor) -> CAShapeLayer {
        let ringPath = UIBezierPath(arcCenter: CGPoint.zero,
                                    radius: 75,
                                    startAngle: 0,
                                    endAngle: .pi * 2,
                                    clockwise: true)
        let layer = CAShapeLayer()
        layer.path = ringPath.cgPath
        layer.lineWidth = 20
        layer.strokeColor = strokeColor.cgColor
        layer.fillColor = fillColor.cgColor
        layer.position = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height-250)

        return layer
    }
    
    //PulsingLayer加入動畫
    private func animatePulsingLayer() {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0
        animation.toValue = 1.3
        animation.duration = 0.8
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        animation.autoreverses = true
        animation.repeatCount = Float.infinity

        pulsatingLayer.add(animation, forKey: "pulsing")
    }

    
    
    //甜甜圈view
    private func createDonutView (percent1: CGFloat, percent2: CGFloat, percent3: CGFloat, percent4: CGFloat, percent5: CGFloat,
                                  color1: UIColor, color2: UIColor, color3: UIColor, color4: UIColor, color5: UIColor,
                                  donutLineWidth: CGFloat, donutRadius: CGFloat, donutCenter: CGPoint) -> UIView {
        var startDegree: CGFloat = 270
        let percentages: [CGFloat] = [percent1, percent2, percent3, percent4, percent5]
        let fractionColors: [UIColor] = [color1, color2, color3, color4, color5]
        let donutView = UIView()
        
        for i in 0...4 {
            let endDegree = startDegree + 360 * percentages[i] / 100
            let fractionPath = UIBezierPath(arcCenter: donutCenter,
                                              radius: donutRadius,
                                              startAngle: .pi / 180 * startDegree,
                                              endAngle: .pi / 180 * endDegree,
                                              clockwise: true)
            
            let fractionLayer = CAShapeLayer()
            fractionLayer.path = fractionPath.cgPath
            
            fractionLayer.strokeColor = fractionColors[i].cgColor
            fractionLayer.lineWidth = donutLineWidth
            fractionLayer.fillColor = UIColor.clear.cgColor
            donutView.layer.addSublayer(fractionLayer)
            
            //加入目前fraction的百分比標籤
            donutView.addSubview(createDonutLabel(percentage: percentages[i], startDegree: startDegree, labelRadius: donutRadius, labelCenter: donutCenter))
            
            startDegree = endDegree
        }
        return donutView
    }
    
    //Pie view
    private func createPieView (percent1: CGFloat, percent2: CGFloat, percent3: CGFloat, percent4: CGFloat, percent5: CGFloat,
                                color1: UIColor, color2: UIColor, color3: UIColor, color4: UIColor, color5: UIColor,
                                pieRadius: CGFloat, pieCenter: CGPoint) -> UIView {
        var startDegree: CGFloat = 270
        let percentages: [CGFloat] = [percent1, percent2, percent3, percent4, percent5]
        let fractionColors: [UIColor] = [color1, color2, color3, color4, color5]
        let pieView = UIView()
        
        for i in 0...4 {
            let endDegree = startDegree + 360 * percentages[i] / 100
            let fractionPath = UIBezierPath()
            fractionPath.move(to: pieCenter)
            fractionPath.addArc(withCenter: pieCenter,
                                radius: pieRadius,
                                startAngle: .pi / 180 * startDegree,
                                endAngle: .pi / 180 * endDegree,
                                clockwise: true)
            
            let fractionLayer = CAShapeLayer()
            fractionLayer.path = fractionPath.cgPath
            
            //NO stroke color, line width
            fractionLayer.fillColor = fractionColors[i].cgColor
            pieView.layer.addSublayer(fractionLayer)
            
            //加入目前百分比標籤
            pieView.addSubview(createDonutLabel(percentage: percentages[i], startDegree: startDegree, labelRadius: pieRadius * 2 / 3, labelCenter: pieCenter))
            
            startDegree = endDegree
        }
        return pieView
    }
    
    //viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.backgroundColor

        //送回圓環layer，叫他pulsatingLayer，讓他動，加入view
        pulsatingLayer = createRingLayer(strokeColor: UIColor.clear, fillColor: UIColor.pulsatingFillColor)
        animatePulsingLayer()
        view.layer.addSublayer(pulsatingLayer)

        //送回圓環layer，叫他trackLayer，加入view
        let trackLayer = createRingLayer(strokeColor: UIColor.trackStrokeColor, fillColor: UIColor.backgroundColor)
        view.layer.addSublayer(trackLayer)

        //送回圓環layer，叫他runningLayer，修圓角，轉180度，描邊線停留在0，加入view
        runningLayer = createRingLayer(strokeColor: UIColor.runningStrokeColor, fillColor: UIColor.clear)
        runningLayer.lineCap = CAShapeLayerLineCap.round
        runningLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1) //逆時針轉90度
        runningLayer.strokeEnd = 0 //描邊線動作停留的相對位置為0
        view.layer.addSublayer(runningLayer)
        
        
        //下載進度百分比標籤，加入view
        percentageLabel.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height-250)
        view.addSubview(percentageLabel)
        
        //下載按鈕，加入view
        downloadButton.frame = CGRect(x: 20, y: view.frame.size.height-100, width: view.frame.size.width-40, height: 50)
        view.addSubview(downloadButton)
        
        //========
        
        //送回donutView，加入view
        view.addSubview(createDonutView(percent1: 20, percent2: 11, percent3: 26, percent4: 28, percent5: 15,
                                        color1: UIColor.Color1, color2: UIColor.Color2, color3: UIColor.Color3, color4: UIColor.Color4, color5: UIColor.Color5,
                                        donutLineWidth: 50, donutRadius: 60, donutCenter: CGPoint(x: view.frame.size.width/4, y: 200)))
        
        view.addSubview(createDonutView(percent1: 17, percent2: 31, percent3: 28, percent4: 12, percent5: 12,
                                        color1: UIColor.Color5, color2: UIColor.Color4, color3: UIColor.Color3, color4: UIColor.Color2, color5: UIColor.Color1,
                                        donutLineWidth: 50, donutRadius: 60, donutCenter: CGPoint(x: view.frame.size.width * 3 / 4, y: 200)))
        //送回pieView，加入view
        view.addSubview(createPieView(percent1: 20, percent2: 11, percent3: 26, percent4: 28, percent5: 15,
                                      color1: UIColor.Color6, color2: UIColor.Color7, color3: UIColor.Color8, color4: UIColor.Color9, color5: UIColor.Color10,
                                      pieRadius: 85, pieCenter: CGPoint(x: view.frame.size.width/4, y: view.frame.size.height/2)))
        
        view.addSubview(createPieView(percent1: 13, percent2: 8, percent3: 42, percent4: 17, percent5: 20,
                                      color1: UIColor.Color10, color2: UIColor.Color9, color3: UIColor.Color8, color4: UIColor.Color7, color5: UIColor.Color6,
                                      pieRadius: 85, pieCenter: CGPoint(x: view.frame.size.width * 3 / 4, y: view.frame.size.height / 2)))
        
    }
    
    
    let urlString = "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/53/b6/33/53b63348-8044-9e0c-6d9a-3e58b434c8ac/mzaf_338250143608298069.plus.aac.p.m4a"
    
    //成功完成後，session 會呼叫以下 delegate 的方法或 completion handler。因為檔案只是暫存的，所以必須在這個 delegate 方法 return 前打開檔案讀取，或是移動到 app’s sandbox container directory 中一個永久的位置。
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("下載完成！")
    }
    
    //下載時，session 會週期性地呼叫以下 delegate 方法，並提供狀態資訊
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percentage = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        print(percentage)

        DispatchQueue.main.async {
            self.percentageLabel.text = "\(Int(percentage * 100))%"
            self.runningLayer.strokeEnd = percentage
        }
    }
    
    @objc func didTapButton() {
        //開始下載
        runningLayer.strokeEnd = 0 //描邊線動作停留的相對位置為0
        
        let urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue())
        
        guard let url = URL(string: urlString) else { return }
        
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
    }
}


//=====extension=====//
extension UIColor {
    static func rgb(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        return UIColor(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
    
    static let backgroundColor = UIColor.rgb(r: 11, g: 16, b: 19)
    static let myLabelColor = UIColor.rgb(r: 252, g: 250, b: 242)
    static let myBurttonColor = UIColor.rgb(r: 54, g: 86, b: 60)
    
    static let pulsatingFillColor = UIColor.rgb(r: 245, g: 237, b: 237)
    static let trackStrokeColor = UIColor.rgb(r: 253, g: 184, b: 178)
    static let runningStrokeColor = UIColor.rgb(r: 208, g: 16, b: 76)
    
    // Donut's fractionLayer colors
    static let Color1 = UIColor.rgb(r: 216, g: 253, b: 236)
    static let Color2 = UIColor.rgb(r: 169, g: 251, b: 215)
    static let Color3 = UIColor.rgb(r: 178, g: 228, b: 219)
    static let Color4 = UIColor.rgb(r: 176, g: 198, b: 206)
    static let Color5 = UIColor.rgb(r: 147, g: 139, b: 161)
    
    // Pie's fractionLayer colors
    static let Color6 = UIColor.rgb(r: 236, g: 248, b: 248)
    static let Color7 = UIColor.rgb(r: 238, g: 228, b: 225)
    static let Color8 = UIColor.rgb(r: 231, g: 216, b: 201)
    static let Color9 = UIColor.rgb(r: 230, g: 190, b: 174)
    static let Color10 = UIColor.rgb(r: 178, g: 150, b: 125)
}
