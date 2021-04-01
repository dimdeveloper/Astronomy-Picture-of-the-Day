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
    var dateArray: [Date] = []
    var imagesCollectionViewArray: [Date : UIImage?] = [:]
    var podObjectsArray: [PODObject] = []
    let today = Date()
    var currentDate = Date()
    let indexPathOfDatePicker: IndexPath = IndexPath(row: 1, section: 0)
    let indexPathOfImage: IndexPath = IndexPath(row: 2, section: 0)
    let indexPathOfDescription: IndexPath = IndexPath(row: 4, section: 0)
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    }
    lazy var tomorrow = Calendar.current.date(byAdding: .day, value: +1, to: currentDate)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let request = Requests()
        initialSetupCollectionView()
   
        
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
        cell.imageView.image = UIImage(named: "imagePlaceholder")
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sizeOfTheCell = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        print(sizeOfTheCell)
        return sizeOfTheCell
    }
    
    func initialSetupCollectionView(){
        print(currentDate)
        print(today)

        for index in 0...9 {
            dateArray.insert(currentDate, at: 0)
            currentDate = yesterday
        }
        
        print(dateArray.count)
        imagesCollectionView.reloadData()
        let itemsCount = CGFloat((imagesCollectionView.numberOfItems(inSection: 0)))
        print(itemsCount)
        imagesCollectionView.setContentOffset(CGPoint(x: 50, y: 0), animated: true)
        imagesCollectionView.reloadData()
    }

}
