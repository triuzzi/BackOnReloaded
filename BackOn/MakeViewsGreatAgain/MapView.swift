//
//  MapView.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 25/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import SwiftUI
import UIKit
import MapKit

class MapCoordinator: NSObject, MKMapViewDelegate {
    let mode: RequiredBy
    let discoverTabController = (UIApplication.shared.delegate as! AppDelegate).discoverTabController
    
    init(mode: RequiredBy) {
        self.mode = mode
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIScreen.main.traitCollection.userInterfaceStyle != .dark ? #colorLiteral(red: 0, green: 0.6529515386, blue: 1, alpha: 1) : #colorLiteral(red: 0.2057153285, green: 0.5236110687, blue: 0.8851857781, alpha: 1)
        renderer.lineWidth = 6.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: TaskAnnotation.self) {
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = false
            view.displayPriority = .required
            return view
        }
        if annotation.isKind(of: MKPointAnnotation.self) {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.canShowCallout = true
            view.displayPriority = .required
            view.pinTintColor = .systemBlue
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard mode == .AroundYouMap else {return}
        guard view.annotation!.isKind(of: TaskAnnotation.self) else {return}
        discoverTabController.showSheet(task: (view.annotation! as! TaskAnnotation).task)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard mode == .AroundYouMap else {return}
        guard !view.annotation!.isKind(of: MKUserLocation.self) else {return}
        discoverTabController.closeSheet()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let location = userLocation.location else { return }
        if location.horizontalAccuracy < MapController.horizontalAccuracy {
            let myLocation = MKPointAnnotation()
            myLocation.coordinate = location.coordinate
            myLocation.title = "You"
            mapView.addAnnotation(myLocation)
            mapView.showsUserLocation = false
        }
    }
    
}

struct MapView: UIViewRepresentable {
    let mode: RequiredBy
    var selectedTask: Task?
    
    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(mode: mode)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let shared = (UIApplication.shared.delegate as! AppDelegate).shared
        let discoverTabController = (UIApplication.shared.delegate as! AppDelegate).discoverTabController
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        let mapSpan = MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        //let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        //longPressGesture.minimumPressDuration = 1.0
        //mapView.addGestureRecognizer(...) quello che serve per riconoscere una gesture
        // vedi https://stackoverflow.com/questions/40844336/create-long-press-gesture-recognizer-with-annotation-pin
        switch mode {
        case .RequestViews:
            mapView.addAnnotation(generateAnnotation(selectedTask!, title: "Your request"))
            mapView.setRegion(MKCoordinateRegion(center:selectedTask!.position.coordinate, span: mapSpan), animated: true)
            return mapView
        case .TaskViews:
            mapView.addAnnotation(generateAnnotation(selectedTask!, title: "\(shared.users[selectedTask!.neederID]?.name ?? "Needer with bad id")'s request"))
            mapView.setRegion(MKCoordinateRegion(center:selectedTask!.position.coordinate, span: mapSpan), animated: true)
            addRoute(mapView: mapView)
            return mapView
        case .DiscoverableViews:
            mapView.addAnnotation(generateAnnotation(selectedTask!, title: "\(shared.discUsers[selectedTask!.neederID]?.name ?? "Needer with bad id")'s request"))
            mapView.setRegion(MKCoordinateRegion(center:selectedTask!.position.coordinate, span: mapSpan), animated: true)
            addRoute(mapView: mapView)
            return mapView
        case .AroundYouMap:
            for discoverable in shared.myDiscoverables.values {
                mapView.addAnnotation(generateAnnotation(discoverable, title: shared.discUsers[discoverable.neederID]?.name ?? "Needer with bad id"))
            }
            if let lastLocation = MapController.lastLocation {
                mapView.setRegion(MKCoordinateRegion(center: lastLocation.coordinate, span: mapSpan), animated: true)
            }
            discoverTabController.baseMKMap = mapView
            return mapView
        }
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {}
    
    private func generateAnnotation( _ Task: Task, title: String) -> TaskAnnotation {
        let taskAnnotation = TaskAnnotation(task: Task)
        taskAnnotation.title = title
        taskAnnotation.subtitle = Task.title
        return taskAnnotation
    }
    
    func addRoute(mapView: MKMapView){
        guard let lastLocation = MapController.lastLocation else {return}
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: lastLocation.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: selectedTask!.position.coordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = false
        request.transportType = .walking
        MKDirections(request: request).calculate { (response, error) in
            guard error == nil, let response = response else {print("Error while adding route:",error!.localizedDescription);return}
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

class TaskAnnotation: NSObject, MKAnnotation {
    @ObservedObject var task: Task
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    init(task: Task) {
        self.task = task
        self.coordinate = task.position.coordinate
        super.init()
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
    @Environment(\.presentationMode) var presentationMode
    @Binding var selection: String
    @State var userLocationAddress: String = "Processing your current location..."
    
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
                if MapController.lastLocation != nil{
                Text(userLocationAddress)
                    .onTapGesture {
                        self.selection = self.userLocationAddress
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }else{
                    if addressCompleter.completer.results.isEmpty {
                        Text("Insert the position of your need")
                    }
                }
                
                ForEach(addressCompleter.completer.results, id: \.hashValue) { currentItem in
                    Text("\(currentItem.title) (\(currentItem.subtitle))")
                        .onTapGesture {
                            self.selection = "\(currentItem.title) (\(currentItem.subtitle))"
                            self.presentationMode.wrappedValue.dismiss()
                        }
                }
            }
        }.onAppear() {
            MapController.coordinatesToAddress(nil) { result, error in
                guard error == nil, let result = result else {return}
                self.userLocationAddress = result
            }
        }
    }
}



//            if parent.mode == .TaskTab {
//                view.image = UIImage(named: "Empty")
//                view.markerTintColor = UIColor(#colorLiteral(red: 0, green: 0.6529515386, blue: 1, alpha: 0))
//                view.glyphTintColor = UIColor(#colorLiteral(red: 0, green: 0.6529515386, blue: 1, alpha: 0))
//                view.titleVisibility = .hidden
//                view.subtitleVisibility = .hidden
//            }
