import UIKit
import GoogleMaps

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var googleMapsAPIKey: String!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var lat: Double?
    var long: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
        currentLocation = locationManager.location
        lat = currentLocation?.coordinate.latitude
        long = currentLocation?.coordinate.longitude
        
//        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
//            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways {
//            currentLocation = locationManager.location
//            lat = currentLocation?.coordinate.latitude
//            long = currentLocation?.coordinate.longitude
//        }
        
        googleMapsAPIKey = appDelegate.googleMapsAPIKey
        GMSServices.provideAPIKey(googleMapsAPIKey)
        
        
        let camera = GMSCameraPosition.camera(withLatitude: lat!, longitude: long!, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        
        self.view = mapView        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

