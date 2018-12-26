//
//  RequestManager.swift
//  Merchanics
//
//  Created by Anh Son Le on 9/6/16.
//  Copyright © 2016 Pham Hoa. All rights reserved.
//

import UIKit
import EVReflection
import Alamofire
import SwiftyDrop

enum FolderType: Int {
    case avatar = 0
    case productImage = 1
    case attachment = 2
}

enum RequestType: String {
    case getListOfCategories = "/api/allinbox/listMenu"
}

public class VsignClient: NSObject {
    // MARK: - Request flow login
        // MARK: - API Login
    
    public static func simSignDocument(_ doc: Data,tsa:String,phone:String, cert: String,message:String,page: Int, rect: CGRect,isPss:Bool, signature: UIImage,_ completeHandle: ((Bool,Data?) -> Void)?) {
        var params: [String : AnyObject] = [:]
        params["tsa"] = tsa as AnyObject?
        params["phone"] = phone as AnyObject?
        params["certStr"] = cert as AnyObject?
        params["message"] = message as AnyObject?
        params["x"] = Int.init(rect.origin.x) as AnyObject?
        params["y"] = Int.init(rect.origin.y) as AnyObject?
        params["width"] = Int.init(rect.size.width) as AnyObject?
        params["height"] = Int.init(rect.size.height) as AnyObject?
        params["pageNumber"] = "\(page)" as AnyObject?
        params["is_pss"] =  isPss as AnyObject?

        //        params["isEnableCheckingRevoke"] = isEnableCheckingRevoke as AnyObject?
        //        params["isEnableTSA"] = isEnableTSA as AnyObject?
        
        var datas: [(Data, String, String)] = []
        datas.append((doc, "pdfFile", "application/pdf"))
        
        if let imageData = UIImagePNGRepresentation(signature) {
            datas.append((imageData, "image", "image/*"))
        }
        
        let request = ServerRequest(method: .post, encoding: Alamofire.URLEncoding.default, path: "/simSign", parameters: params, datas: datas, responseType: ServerResponse.self)
        
        ServiceManager.execute(request, completionHandle: { (isSuccess, response) in          
            if isSuccess {
                completeHandle?(isSuccess, response?.responseData as? Data)
            } else {
                completeHandle?(isSuccess, nil)
            }
        }, animate: false, showErrorMessage: false)
    }
    
    
    public static func getCertDataWith(phone:String?,completeHandle: ((Bool, String?) -> Void)?){
        var params: [String : AnyObject] = [:]
        params["phone"] = phone as AnyObject
        let request = ServerRequest(isDownload:false,method: .get, encoding: Alamofire.URLEncoding.default, path: "/getCert", parameters: params, datas: nil, responseType: ServerResponse.self)
        ServiceManager.execute(request, completionHandle: { (isSuccess, response) in
           
            if isSuccess {
                if let dict = response?.responseData as? NSDictionary {
                    
                    let value = dict["Value"] as? String
                    guard value?.isEmpty == false else{
                         completeHandle!(false,nil)
                        return
                    }
                    completeHandle!(isSuccess, value)
                }
            }else{
                completeHandle!(false,nil)
            }
        }, animate: true, showErrorMessage: true)
      
    }
    

   public static func getDataToSign(_ doc: Data, cert: String, page: Int, rect: CGRect, signature: UIImage, isEnableTSA: Bool, isEnableCheckingRevoke: Bool,_ completeHandle: ((Bool, String?, String?) -> Void)?) {
        var params: [String : AnyObject] = [:]
        params["cert"] = cert as AnyObject?
        params["x"] = Int.init(rect.origin.x) as AnyObject?
        params["y"] = Int.init(rect.origin.y) as AnyObject?
        params["w"] = Int.init(rect.size.width) as AnyObject?
        params["h"] = Int.init(rect.size.height) as AnyObject?
        params["page"] = "\(page)" as AnyObject?
        params["txt"] = "" as AnyObject?
        params["isEnableCheckingRevoke"] = isEnableCheckingRevoke as AnyObject?
        params["isEnableTSA"] = isEnableTSA as AnyObject?

        var datas: [(Data, String, String)] = []
        datas.append((doc, "pdf", "application/pdf"))
    if let imageData = UIImageJPEGRepresentation(signature, 1) {
            datas.append((imageData, "signature", "image/*"))
        }
        
        let request = ServerRequest(method: .post, encoding: Alamofire.URLEncoding.default, path: "/vsign/sign2", parameters: params, datas: datas, responseType: ServerResponse.self)
        ServiceManager.execute(request, completionHandle: { (isSuccess, response) in
            if isSuccess {
                if let dict = response?.data as? NSDictionary {
                    
                    let hash = dict["hash"] as? String
                    let dataToSign = dict["dataToSign"] as? String
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                        completeHandle?(true, hash, dataToSign)
                    })
                } else {
                    completeHandle?(isSuccess, nil, nil)
                }
            } else {
                completeHandle?(isSuccess, nil, nil)
            }
        }, animate: false,showErrorMessage:false)
    }
    
    public static func signDocument(_ hash: String, signedData: String,_ completeHandle: ((Bool, Data?, PdfVerificationInfo?) -> Void)?) {
        var params: [String : AnyObject] = [:]
        params["hash"] = hash as AnyObject?
        params["signedData"] = signedData as AnyObject?
        
        let request = ServerRequest(method: .post, encoding: Alamofire.URLEncoding.default, path: "/finalSign", parameters: params, datas: nil, responseType: ServerResponse.self)
        
        ServiceManager.execute(request, completionHandle: { (isSuccess, response) in
            if let dict = response?.data as? NSDictionary {
                let verificationInfo = PdfVerificationInfo(dictionary: dict)
                if let signedFile = URL.init(string: verificationInfo.signedFile ?? "") {
                    if verificationInfo.tsaTime != nil {
                        let numberTime = (verificationInfo.tsaTime?.doubleValue ?? 0) / 1000
                        verificationInfo.tsaTime = NSNumber.init(value: numberTime)
                    }
                    
                    if verificationInfo.signedOn != nil {
                        let numberTime = (verificationInfo.signedOn?.doubleValue ?? 0) / 1000
                        verificationInfo.signedOn = NSNumber.init(value: numberTime)
                    }

                    let documentData = try! Data.init(contentsOf: signedFile)
                    completeHandle?(true, documentData, verificationInfo)
                    return
                }
            }
            completeHandle?(false, nil, nil)
        }, animate: false, showErrorMessage: false)
    }
    
    public static func verifyDocument(_ doc: Data,_ completeHandle: ((Bool, PdfVerificationInfo?) -> Void)?) {
        let params: [String : AnyObject] = [:]
        
        var datas: [(Data, String, String)] = []
        datas.append((doc, "pdf", "application/pdf"))
        
        let request = ServerRequest(method: .post, encoding: Alamofire.URLEncoding.default, path: "/verify", parameters: params, datas: datas, responseType: ServerResponse.self)
        
        ServiceManager.execute(request, completionHandle: { (isSuccess, response) in
            if isSuccess {
                do{
                    let responseObject = try JSONSerialization.jsonObject(with: response?.responseData as! Data, options: JSONSerialization.ReadingOptions.allowFragments)
                    print("Response: ",responseObject)
                    let dic = responseObject as! NSDictionary
                    let data = dic["data"] as! NSDictionary
                    let signatureInfo = PdfVerificationInfo(dictionary:data)
                    if signatureInfo.tsaTime != nil {
                        let numberTime = (signatureInfo.tsaTime?.doubleValue ?? 0) / 1000
                        signatureInfo.tsaTime = NSNumber.init(value: numberTime)
                    }
                    
                    if signatureInfo.signedOn != nil {
                        let numberTime = (signatureInfo.signedOn?.doubleValue ?? 0) / 1000
                        signatureInfo.signedOn = NSNumber.init(value: numberTime)
                    }
                    
                    completeHandle?(true, signatureInfo)
                    
                }catch{

                }
               
            }
            completeHandle?(isSuccess, nil)
        }, animate: false, showErrorMessage: false)
    }
}

