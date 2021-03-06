////
////  UserPreview.swift
////  BackOn
////
////  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 11/02/2020.
////  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
////
//
//import SwiftUI
//
//struct UserPreviewNeeder: View {
//    var user: UserInfo
//    var descr: String
//    var whiteText: Bool
//    var textColor: Color{
//        get {
//            return whiteText ? Color.white : Color.black
//        }
//    }
//
//    init(user: UserInfo, whiteText: Bool) {
//        self.user = user
//        descr = ""
//        self.whiteText = whiteText
//    }
//
//    var body: some View {
//        HStack {
//            Avatar(image: user.profilePic)
//            Text("\(user.name)\n\(user.surname)")
//                .font(.title)
//                .fontWeight(.regular)
//                .foregroundColor(textColor)
//                .scaleEffect(0.9)
//                .lineLimit(2)
//            Spacer()
//        }
//    }
//}
//
