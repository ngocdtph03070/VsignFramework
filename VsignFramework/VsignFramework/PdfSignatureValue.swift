//
//  PdfSignatureValue.swift
//  Vsign
//
//  Created by Pham Hoa on 4/18/17.
//  Copyright © 2017 Pham Hoa. All rights reserved.
//

import Foundation
import EVReflection

class SignaturePosition: EVObject {
    var llx: NSNumber?
    var lly: NSNumber?
    var urx: NSNumber?
    var ury: NSNumber?
}

class PdfVerificationInfo: EVObject {
    var includeSignature: NSNumber?
    var signatureWholeDocument: NSNumber?
    var revision: NSNumber?
    var totalRevision: NSNumber?
    var documentIsValid: NSNumber?
    var digestAlg: String?
    var encryptAlg: String?
    var signer: String?
    var email: String?
    var signedOn: NSNumber?
    var tsaService: String?
    var tsaTime: NSNumber?
    var tsaValid: NSNumber?
    var location: String?
    var reason: String?
    var signaturePosition: SignaturePosition?
    var name: String?
    var signaturePage: NSNumber?
    var signatureImage: String? {
        didSet {
            if (self.signatureImage ?? "").contains("://webshot.") {
                self.signatureImage = self.signatureImage!.replacingOccurrences(of: "://webshot.", with: "://demo.")
            }
        }
    }
    var includeTSA: NSNumber?
    var includeCRL: NSNumber?
    var crlValid: NSNumber?
    var signedFile: String? {
        didSet {
            if (self.signedFile ?? "").contains("://webshot.") {
                self.signedFile = self.signedFile!.replacingOccurrences(of: "://webshot.", with: "://demo.")
            }
        }
    }
    var expire: NSNumber?

    override func propertyMapping() -> [(keyInObject: String?, keyInResource: String?)] {
        let mappedProperties: [(String?, String?)] = [("includeSignature", "includeSignature"),
                                                      ("signatureWholeDocument", "signatureWholeDocument"),
                                                      ("totalRevision", "totalRevision"),
                                                      ("documentIsValid", "documentIsValid"),
                                                      ("digestAlg", "digestAlg"),
                                                      ("encryptAlg", "encryptAlg"),
                                                      ("signedOn", "signedOn"),
                                                      ("tsaService", "tsaService"),
                                                      ("tsaTime", "tsaTime"),
                                                      ("tsaValid", "tsaValid"),
                                                      ("signaturePosition", "signaturePosition"),
                                                      ("signaturePage", "signaturePage"),
                                                      ("signatureImage", "signatureImage"),
                                                      ("includeTSA", "includeTSA"),
                                                      ("includeCRL", "includeCRL"),
                                                      ("crlValid", "crlValid"),
                                                      ("signedFile", "signedFile")]
        
        return mappedProperties
    }
}
