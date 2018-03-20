import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    //https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.870943,151.190311&radius=1000&rankby=prominence&sensor=true&key=AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg
    var locationManager = CLLocationManager()
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var addresslbl: UILabel!
    
    lazy var googleClient = GoogleClient()
    var currentLocation: CLLocation = CLLocation(latitude: 42.361145, longitude: -71.057083)
    var locationPetrol : String = "petrol"
    var locationGasStation : String = "gas_station"
    var locationFood : String = "food"
    var searchRadius : Int = 1000
    
    //part of exapandable search
    var leftConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.delegate = self
        //self.navigationController?.isNavigationBarHidden = true
        locationManager.requestWhenInUseAuthorization()
        //        let jsonURLString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.870943,151.190311&radius=1000&rankby=prominence&sensor=true&key=AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg"
        //        fetchGoogleData(forLocation: currentLocation, locationName: locationName, searchRadius: searchRadius )
        
        //        expandable search bar
        //        https://stackoverflow.com/questions/38580175/swift-expandable-search-bar-in-header
        //        expandableview to end of code
        addingExpandableSearch()
    }
    
    
    
    func addingExpandableSearch(){
        // Expandable area.
        let expandableView = ExpandableView()
        navigationItem.titleView = expandableView
        
        // Search button.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(toggle))
        
        // Search bar.
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        expandableView.addSubview(searchBar)
        leftConstraint = searchBar.leftAnchor.constraint(equalTo: expandableView.leftAnchor)
        leftConstraint.isActive = false
        searchBar.rightAnchor.constraint(equalTo: expandableView.rightAnchor).isActive = true
        searchBar.topAnchor.constraint(equalTo: expandableView.topAnchor).isActive = true
        searchBar.bottomAnchor.constraint(equalTo: expandableView.bottomAnchor).isActive = true
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        //DispatchQueue.main.async {
        //locationManager.stopUpdatingLocation()
        mapView.clear()
        self.fetchGoogleData(forLocation: location, locationName: self.locationGasStation, searchRadius: self.searchRadius )
        self.fetchGoogleData(forLocation: location, locationName: self.locationPetrol, searchRadius: self.searchRadius )
        self.fetchGoogleData(forLocation: location, locationName: self.locationFood, searchRadius: self.searchRadius )
    }
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            
            self.addresslbl.text = lines.joined(separator: "\n")
            
            let labelHeight = self.addresslbl.intrinsicContentSize.height
            self.mapView.padding = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0, bottom: labelHeight, right: 0)
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
    
    //MARK: Google Directions functions
    func drawPathByCoordinates(startLocation: CLLocation, destLocation: CLLocation) {
        
        
        
        
        
    }
    
}

extension ViewController {
    func fetchGoogleData(forLocation: CLLocation, locationName: String, searchRadius: Int) {
        //        let possibleTypes = ["bar", "gas_station", "restaurant"]
        let group1 = DispatchGroup()
        group1.enter()
        googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
            DispatchQueue.main.sync{
                let places = response.results
                for place in places {
                    let marker = PlaceMarker(place: place)
                    marker.title = place.name
                    marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                    switch true{
                    case place.types.contains("gas_station"),place.types.contains("petrol"):
                        marker.icon = UIImage(named: "Gas_station")
                        marker.map = self.mapView
                    case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                        marker.icon = UIImage(named: "Food")
                        marker.map = self.mapView
                    default:
                        break
                    }
                    
                }
                group1.leave()
            }
        }
        let group2 = DispatchGroup()
        group1.notify(queue: .main, execute: {
            group2.enter()
            self.googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
                        DispatchQueue.main.sync{
                            let places = response.results
                            for place in places {
                                let marker = PlaceMarker(place: place)
                                marker.title = place.name
                                marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                                switch true{
                                case place.types.contains("gas_station"):
                                    marker.icon = UIImage(named: "Gas_station")
                                    marker.map = self.mapView
                                case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                                    marker.icon = UIImage(named: "Food")
                                    marker.map = self.mapView
                                default:
                                    break
                                }
                            }
                            group2.leave()
                        }
                    }
                    group2.leave()
                }
                
            }
        })
        
        group2.notify(queue: .main, execute: {
            self.googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
                DispatchQueue.main.sync{
                    let places = response.results
                    for place in places {
                        let marker = PlaceMarker(place: place)
                        marker.title = place.name
                        marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                        switch true{
                        case place.types.contains("gas_station"):
                            marker.icon = UIImage(named: "Gas_station")
                            marker.map = self.mapView
                        case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                            marker.icon = UIImage(named: "Food")
                            marker.map = self.mapView
                        default:
                            break
                        }
                    }
                }
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var intrinsicContentSize: CGSize {
        return UILayoutFittingExpandedSize
    }
}






