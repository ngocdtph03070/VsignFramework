//
//  Utils.swift
//  Vsign
//
//  Created by Pham Hoa on 3/21/17.
//  Copyright © 2017 Pham Hoa. All rights reserved.
//

import Foundation
import NVActivityIndicatorView
class Utils: NSObject {
    /*
    class func getPdfFiles() -> [String] {
        // Get the document directory url
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            
            // if you want to filter the directory contents you can do like this:
            let pdfFiles = directoryContents.filter{ $0.pathExtension == "pdf" }
            let pdfFileNames = pdfFiles.map{ $0.deletingPathExtension().lastPathComponent }
            return pdfFileNames
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return []
    }    
    */
    
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }

  
    
    class func showAlert(_ title: String?,_ mess: String, okTitle: String, cancelTitle: String, completedHanler: ((Bool)->())?) {
        guard let topVC = self.topViewController() else {return}
        let alertController = UIAlertController(title: title, message: mess, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: okTitle, style: .default) { (action:UIAlertAction!) in
            topVC.dismiss(animated: false, completion: nil)
            completedHanler?(true)
        }
        let CancelAction = UIAlertAction(title: cancelTitle, style: .default) { (action:UIAlertAction!) in
            topVC.dismiss(animated: false, completion: nil)
            completedHanler?(false)
        }
        alertController.addAction(OKAction)
        alertController.addAction(CancelAction)
        topVC.present(alertController, animated: true, completion:nil)
    }

    class func enumCount<T: Hashable>(_: T.Type) -> Int {
        var i = 1
        while (withUnsafePointer(to: &i, {
            return $0.withMemoryRebound(to: T.self, capacity: 1, { return $0.pointee })
        }).hashValue != 0) {
            i += 1
        }
        return i
    }
    
    class func createGradientLayer(frame: CGRect, colors: [CGColor]) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.frame = frame
        layer.colors = colors
        return layer
    }
    
    class func verifyDoc(_ data: Data, completedHandler: ((_ isSigned: Bool, _ signer: String?,_ signedOn: NSNumber?,_ verificationData: Data?)->())?) {
        VsignClient.verifyDocument(data) { (isSuccess, verificationInfo) in
            let isSigned = verificationInfo?.includeSignature?.boolValue ?? false
            let signer = verificationInfo?.signer ?? nil
            var signedOn: NSNumber?
            
            if isSigned && verificationInfo != nil {
                let verificationData = NSKeyedArchiver.archivedData(withRootObject: verificationInfo!)
                if verificationInfo?.includeTSA == true {
                    signedOn = verificationInfo?.tsaTime
                } else {
                    signedOn = verificationInfo?.signedOn
                }

                completedHandler?(isSigned, signer, signedOn, verificationData)
                return
            } else {
                completedHandler?(isSigned, signer, signedOn, nil)
            }
        }
    }
}

