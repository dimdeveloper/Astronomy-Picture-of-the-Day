//
//  MainTableViewController.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.

import UIKit

class MainTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var imageDescription: UITextView!
    var dateArray: [Date] = [] {
        didSet {
            dateArray.sort { (date1, date2) -> Bool in
                return date1 < date2
            }
        }
    }
    var imagesCollectionViewArray: [Date : UIImage?] = [:]
    var podObjectsArray: [PODObject] = []
    let today = Date()
    var imagesDictionary: [Date : UIImage?] = [:] {
        didSet {
            print("changed!")
            DispatchQueue.main.async {
                self.imagesCollectionView.reloadData()
            }
            
        }
    }
    var podObjectDictionary: [Date : PODObject?] = [:]
    let request = Requests()
    lazy var currentDate = Calendar.current.date(byAdding: .day, value: -1, to: today)!
    var indexPathForVisibleCell = IndexPath(row: 9, section: 0)
    let indexPathOfDatePicker: IndexPath = IndexPath(row: 1, section: 0)
    let indexPathOfImage: IndexPath = IndexPath(row: 2, section: 0)
    let indexPathOfDescription: IndexPath = IndexPath(row: 4, section: 0)
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    }
    lazy var tomorrow = Calendar.current.date(byAdding: .day, value: +1, to: currentDate)
    var currentObject: PODObject!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetupCollectionView()
        fetchObject(withDate: Calendar.current.date(byAdding: .day, value: -1, to: today)!)
        
   
        
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case indexPathOfDatePicker:
            return datePicker.frame.height
        case indexPathOfImage:
            return 300
        case indexPathOfDescription:
            return 450
        default:
            return 44
        }
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dateArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        let date = dateArray[indexPath.row]
        
        if imagesDictionary[date] == nil {
            cell.imageView.image = UIImage(named: "imagePlaceholder")
        } else {
            cell.imageView.image = imagesDictionary[date] as? UIImage
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sizeOfTheCell = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        return sizeOfTheCell
    }
    func fetchObject(withDate date: Date){
        request.fetchNASAPOD(date: date) { object in
            print("TheDate is \(date)")
            if let object = object {
                self.imagesDictionary[date] = self.updateImage(imageStringURL: object.imageURL)
                
                self.podObjectDictionary[date] = object
                DispatchQueue.main.async {
                    self.updateTableView(with: object)
                }
            }
        }
    }
    func initialSetupCollectionView(){

        for _ in 0...9 {
            dateArray.insert(currentDate, at: 0)
            currentDate = yesterday
        }
        imagesCollectionView.reloadData()
    }
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
      
        let visibleCell = imagesCollectionView.visibleCells.first!
        indexPathForVisibleCell = imagesCollectionView.indexPath(for: visibleCell)!
        print(dateArray[indexPathForVisibleCell.row])
        fetchObject(withDate: dateArray[indexPathForVisibleCell.row])
        //imagesCollectionView.reloadItems(at: [indexPathForVisibleCell])
        print("IndexPath for visibleCell is \(indexPathForVisibleCell)")
    }
    func updateTableView(with object: PODObject){
        imageName.text = object.title
    }
    func updateImage(imageStringURL: String) -> UIImage? {
        guard let imageURL = URL(string: imageStringURL), let imageData = try? Data(contentsOf: imageURL) else {
            print("Error retreiving image!")
            return nil}
           return UIImage(data: imageData)
    }

}
