//
//  MapView.swift
//  BackOn
//
//  Created by Giancarlo Sorrentino on 25/02/2020.
//  Copyright © 2020 Emmanuel Tesauro. All rights reserved.
//

import SwiftUI
import UIKit
import MapKit

enum MapFor {
    case TaskTab
    case DiscoverTab
    case DiscoverDetailedModal
    case TaskDetailedModal
    case RequestDetailedModal
}

struct MapView: UIViewRepresentable {
//    let shared = (UIApplication.shared.delegate as! AppDelegate).shared
    let mapController = (UIApplication.shared.delegate as! AppDelegate).mapController
    let mode: MapFor
    var selectedCommitment: Commitment?
    
    class CommitmentAnnotation: NSObject, MKAnnotation {
        var commitment: Commitment
        // This property must be key-value observable, which the `@objc dynamic` attributes provide.
        @objc dynamic var coordinate: CLLocationCoordinate2D
        var title: String?
        var subtitle: String?
        init(commitment: Commitment) {
            self.commitment = commitment
            self.coordinate = commitment.position.coordinate
            super.init()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIScreen.main.traitCollection.userInterfaceStyle != .dark ? #colorLiteral(red: 0, green: 0.6529515386, blue: 1, alpha: 1) : #colorLiteral(red: 0.2057153285, green: 0.5236110687, blue: 0.8851857781, alpha: 1)
            renderer.lineWidth = 6.0
            return renderer
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else {return nil}
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = false
            view.displayPriority = .required
            if parent.mode == .TaskTab {
                view.image = UIImage(named: "Empty")
                view.markerTintColor = UIColor(#colorLiteral(red: 0, green: 0.6529515386, blue: 1, alpha: 0))
                view.glyphTintColor = UIColor(#colorLiteral(red: 0, green: 0.6529515386, blue: 1, alpha: 0))
            }
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard parent.mode == .DiscoverTab else {return}
            guard !view.annotation!.isKind(of: MKUserLocation.self) else {return}
            (UIApplication.shared.delegate as! AppDelegate).detailedViewController.showSheet(commitment: (view.annotation! as! CommitmentAnnotation).commitment)
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard parent.mode == .DiscoverTab else {return}
            guard !view.annotation!.isKind(of: MKUserLocation.self) else {return}
            (UIApplication.shared.delegate as! AppDelegate).detailedViewController.closeSheet()
        }
        
    }
    
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        let mapSpan = MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsUserLocation = true;
        //let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        //longPressGesture.minimumPressDuration = 1.0
        //mapView.addGestureRecognizer(...) quello che serve per riconoscere una gesture
        // vedi https://stackoverflow.com/questions/40844336/create-long-press-gesture-recognizer-with-annotation-pin
        switch mode {
        case .RequestDetailedModal:
            mapView.addAnnotation(generateAnnotation(selectedCommitment!, title: "You"))
            mapView.setRegion(MKCoordinateRegion(center:selectedCommitment!.position.coordinate, span: mapSpan), animated: true)
            return mapView
        case .TaskTab:
            mapView.isScrollEnabled = false;
            mapView.isRotateEnabled = false;
            mapView.isPitchEnabled = false;
            mapView.isZoomEnabled = false;
            mapView.showsUserLocation = false;
            mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: selectedCommitment!.position.coordinate.latitude + 0.00035, longitude: selectedCommitment!.position.coordinate.longitude) , span: mapSpan), animated: true)
            mapView.addAnnotation(generateAnnotation(selectedCommitment!, title: ""))
            return mapView
        case .TaskDetailedModal:
            mapView.addAnnotation(generateAnnotation(selectedCommitment!, title: selectedCommitment!.userInfo.name))
            mapView.setRegion(MKCoordinateRegion(center:selectedCommitment!.position.coordinate, span: mapSpan), animated: true)
            addRoute(mapView: mapView)
            return mapView
        case .DiscoverDetailedModal:
            let discoverCommitment = (UIApplication.shared.delegate as! AppDelegate).detailedViewController.commitment!
            mapView.addAnnotation(generateAnnotation(discoverCommitment, title: discoverCommitment.userInfo.name))
            mapView.setRegion(MKCoordinateRegion(center:discoverCommitment.position.coordinate, span: mapSpan), animated: true)
            addRoute(mapView: mapView)
            return mapView
        case .DiscoverTab:
            for (_, discoverableCommitment) in (UIApplication.shared.delegate as! AppDelegate).shared.discoverSet {
                mapView.addAnnotation(generateAnnotation(discoverableCommitment, title: discoverableCommitment.userInfo.name))
            }
            mapView.setRegion(MKCoordinateRegion(center: mapController.lastLocation!.coordinate, span: mapSpan), animated: true)
            (UIApplication.shared.delegate as! AppDelegate).detailedViewController.baseMKMap = mapView
            return mapView
        }
        
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
    }
    
    private func generateAnnotation( _ commitment: Commitment, title: String) -> MKAnnotation {
        let commitmentAnnotation = CommitmentAnnotation(commitment: commitment)
        commitmentAnnotation.title = title
        commitmentAnnotation.subtitle = commitment.title
        return commitmentAnnotation
    }
    
    func addRoute(mapView: MKMapView){
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: mapController.lastLocation!.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: selectedCommitment!.position.coordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        MKDirections(request: request).calculate { (response, error) in
            guard error == nil, let response = response else {print(error!.localizedDescription);return}
            var fastestRoute: MKRoute = response.routes[0]
            for route in response.routes {
                if route.expectedTravelTime < fastestRoute.expectedTravelTime {
                    fastestRoute = route
                }
            }
            mapView.addOverlay(fastestRoute.polyline, level: .aboveRoads)
        }
    }
}


struct SearchBar : UIViewRepresentable {
    @Binding var text : String
    
    class Coordinator : NSObject, UISearchBarDelegate {
        @Binding var text : String
        
        init(_ text : Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.endEditing(true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator($text)
    }
    
    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.searchBarStyle = .minimal
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}

struct searchLocation: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var selection: String
    @State var userLocationAddress: String = "Processing your current location..."
    let mapController = (UIApplication.shared.delegate as! AppDelegate).mapController
    
    class AddressCompleterHandler: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
        @Published var completer = MKLocalSearchCompleter()
        override init() {
            super.init()
            completer.delegate = self
        }
    }
    @ObservedObject var addressCompleter = AddressCompleterHandler()
    
    var body: some View {
        Form {
            Section (header: SearchBar(text: $addressCompleter.completer.queryFragment)) {
                Text(userLocationAddress).onTapGesture {
                    self.selection = self.userLocationAddress
                    self.presentationMode.wrappedValue.dismiss()
                }
                ForEach(addressCompleter.completer.results, id: \.hashValue) { currentItem in
                    Text("\(currentItem.title) (\(currentItem.subtitle))").onTapGesture {
                        self.selection = "\(currentItem.title) (\(currentItem.subtitle))"
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }.onAppear() {
            self.mapController.coordinatesToAddress() { result in
                self.userLocationAddress = result
            }
        }
    }
}