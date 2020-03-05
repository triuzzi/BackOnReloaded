//
//  DiscoverDetailedView.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 04/03/2020.
//  Copyright © 2020 Emmanuel Tesauro. All rights reserved.
//

import SwiftUI
import MapKit

struct FullDiscoverView: View {
    @ObservedObject var shared = (UIApplication.shared.delegate as! AppDelegate).shared
    @ObservedObject var mapController = (UIApplication.shared.delegate as! AppDelegate).mapController
    @State var showDetailedModal: Bool = false
     
    var body: some View {
        VStack (alignment: .leading, spacing: 10){
            Picker(selection: $shared.fullDiscoverViewMode, label: Text("Select")) {
                Text("List").tag(1)
                Text("Map").tag(0)
            }.pickerStyle(SegmentedPickerStyle()).labelsHidden().padding(.horizontal)
            if shared.fullDiscoverViewMode == 1 {
                VStack (alignment: .center, spacing: 25){
                    ForEach(shared.discoverArray(), id: \.ID) { currentDiscover in
                        Button(action: {
                            (UIApplication.shared.delegate as! AppDelegate).detailedViewController.commitment = currentDiscover
                            self.showDetailedModal = true
                        }) {
                            HStack {
                                UserPreview(user: currentDiscover.userInfo, description: "\(currentDiscover.title)", whiteText: self.darkMode)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundColor(Color(UIColor.systemBlue))
                            }.padding(.horizontal, 15)
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }.padding(.top,20)
            } else {
                MapView(mode: .DiscoverTab).cornerRadius(20)
            }
        }
        .padding(.top, 40)
        .background(Color("background"))
        .edgesIgnoringSafeArea(.all)
//        .sheet(isPresented: self.$showDetailedModal, content: {DiscoverFullDetailedView()})
    }
}

struct DiscoverInfoDetailedView: View {
    let mapController = (UIApplication.shared.delegate as! AppDelegate).mapController
    let selectedCommitment = (UIApplication.shared.delegate as! AppDelegate).detailedViewController.commitment
    
    var body: some View {
        VStack(alignment: .leading) {
                    if selectedCommitment != nil{
                        
                        VStack(alignment: .leading){
                            
                            HStack{
                                Avatar(image: selectedCommitment!.userInfo.profilePic)
                                VStack(alignment: .leading){
                                    Text(selectedCommitment!.userInfo.identity)
                                        .fontWeight(.bold)
                                        .font(Font.custom("SF Pro Text", size: 23))
                                        .foregroundColor(.black)
                                        .animation(.easeOut(duration: 0))
                                    Text(selectedCommitment!.title)
                                        .fontWeight(.regular)
                                        .font(Font.custom("SF Pro Text", size: 17))
                                        .foregroundColor(.black)
                                        .animation(.easeOut(duration: 0))
                                }.padding(.horizontal)
                                
                                Spacer()
                                CloseButton(externalColor: #colorLiteral(red: 0.8717954159, green: 0.7912596464, blue: 0.6638498306, alpha: 1), internalColor: #colorLiteral(red: 0.4917932749, green: 0.4582487345, blue: 0.4234881997, alpha: 1))
                            }.frame(height: 54).padding().background(Color(#colorLiteral(red: 0.9294117647, green: 0.8392156863, blue: 0.6901960784, alpha: 1)))
        //                        .cornerRadius(20, corners: [.topLeft, .topRight])
                         
        //                Text("Address")
        //                    .foregroundColor(.secondary)
        //                    .fontWeight(.regular)
        //                    .font(Font.custom("SF Pro Text", size: 17))
        //                    .padding(.top, 10).padding(.horizontal, 25)
        //                Text("Ciao")
        //                Divider().padding(.horizontal, 25)
                            
                            if !selectedCommitment!.descr.isEmpty{
                                Text(selectedCommitment!.descr)
        //                    .lineLimit(5)
                                .fontWeight(.regular)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(Font.custom("SF Pro Text", size: 19))
        //                        .frame(height: 90)
                                    .padding(.horizontal, 25).padding(.top, 5).padding(.bottom, 10)
                                    .animation(.easeOut(duration: 0))
                            }
                            
        //                    Divider().padding(.horizontal, 25)
                            
                            HStack{
                                Spacer()
                                OpenInMapsButton(isFilled: false, selectedCommitment: selectedCommitment! ).padding(.horizontal)
                                DoItButton().padding(.horizontal)
                                Spacer()
                            }.padding(.vertical, 5)
                            //                .padding(.top, 10)
                            
                            Text("Address")
                                .foregroundColor(.secondary)
                                .fontWeight(.regular)
                                .font(Font.custom("SF Pro Text", size: 17))
                                .padding(.top, 10).padding(.horizontal, 25)
                                .animation(.easeOut(duration: 0))
                            
                            Divider().padding(.horizontal, 25).padding(.top, -5)
                            //                    Text(selectedCommitment!.textAddress!)
                            Text("Via Gianluca Rossi 16\n84088 Siano, Provincia di Salerno\nItalia")
                                .padding(.horizontal, 25).padding(.top, -5)
                                .animation(.easeOut(duration: 0))
                            
                            Text("Scheduled Date")
                                .foregroundColor(.secondary)
                                .fontWeight(.regular)
                                .font(Font.custom("SF Pro Text", size: 17))
                                .padding(.top, 10).padding(.horizontal, 25)
                            .animation(.easeOut(duration: 0))
                            
                            Divider().padding(.horizontal, 25).padding(.top, -5)
                            //                    Text(selectedCommitment!.textAddress!)
                            Text( "\(self.selectedCommitment!.date, formatter: customDateFormat)"
//                                self.shared.dateFormatter.string(from: self.selectedCommitment!.date)
                            )
                                .padding(.horizontal, 25).padding(.top, -5)
                                .animation(.easeOut(duration: 0))
                        }
                            .onAppear{
                            if self.mapController.lastLocation != nil {
                                self.selectedCommitment!.requestETA(source: self.mapController.lastLocation!)
                            }
                        }
                    } else{
                        EmptyView()
                    }
                }
    }
}

struct DiscoverFullDetailedView: View {
    var body: some View {
        VStack {
            ZStack {
                MapView(mode: .DiscoverDetailedModal)
                    .statusBar(hidden: true)
                    .edgesIgnoringSafeArea(.all)
                    .frame(height: 515)
                CloseButton()
                    .offset(x:173, y:-265)
            }
            DiscoverInfoDetailedView()
        }
    }
}

struct DiscoverSheetView: View {
    @ObservedObject var detailedViewController = (UIApplication.shared.delegate as! AppDelegate).detailedViewController

    var body: some View {
        SheetView(isOpen: $detailedViewController.showSheet, content: {DiscoverInfoDetailedView()})
    }
}


class DetailedViewController: ObservableObject {
    @Published var showSheet = false
    @Published var commitment: Commitment?
    @Published var baseMKMap: MKMapView?
    
    func showSheet(commitment: Commitment) {
        self.commitment = commitment
        showSheet = true
    }
    
    func closeSheet() {
        showSheet = false
        commitment = nil
        baseMKMap?.deselectAnnotation(baseMKMap?.selectedAnnotations.first, animated: true)
    }
}