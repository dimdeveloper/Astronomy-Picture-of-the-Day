//
//  MainTableViewController.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.

import UIKit

class MainTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    

    @IBOutlet weak var chevronLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var imageDescription: UITextView!
    
    @IBAction func datePickerDateChanged(_ sender: UIDatePicker) {
        currentDate = datePicker.date
        initialSetupCollectionView()
        print("DatePickerDate when datePickerIsCanged is \(datePicker.date)")
//        for cell in imagesCollectionView.visibleCells {
//            print(imagesCollectionView.indexPath(for: cell))
//        }
    }
    
    var chevronRotationAngle: CGFloat = 0
    var isDatePickerHidden: Bool = true {
        didSet {
            chevronRotationAngle = isDatePickerHidden ? CGFloat.pi/2 : -CGFloat.pi/2
            UIView.animate(withDuration: 0.3) {
                self.chevronLabel.transform = CGAffineTransform(rotationAngle: self.chevronRotationAngle)
                
            }
        }
    }
    var dateArray: [Date] = [] {
        didSet {
            dateArray.sort { (date1, date2) -> Bool in
                return date1 < date2
            }
        }
    }
    let imagesCollectionViewLayout = SnappingFlowLayout()
    let today = Date()
    var imagesDictionary: [Date : UIImage?] = [:] {
        didSet {
            print("changed!")
            DispatchQueue.main.async {
                self.imagesCollectionView.reloadData()
            }
            
        }
    }
    var podObjectDictionary: [Date : PODObject] = [:]
    let request = Requests()
    lazy var currentDate = today {
        didSet {
            datePicker.date = currentDate
            if let object = podObjectDictionary[currentDate] {
                updateTableView(with: object)
            } else {
                fetchObject(withDate: currentDate)
            }
        }
    }
    var indexPathForVisibleCell: IndexPath? {
        let centerX = imagesCollectionView.bounds.midX
        let centerY = imagesCollectionView.bounds.midY
        let centerCollectionView = CGPoint(x: centerX, y: centerY)
        return imagesCollectionView.indexPathForItem(at: centerCollectionView)
    }
    let indexPathOfDateLabel: IndexPath = IndexPath(row: 0, section: 0)
    let indexPathOfDatePicker: IndexPath = IndexPath(row: 1, section: 0)
    let indexPathOfImage: IndexPath = IndexPath(row: 2, section: 0)
    let indexPathOfDescription: IndexPath = IndexPath(row: 4, section: 0)
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
    }
    var currentObject: PODObject!
    override func viewDidLoad() {
        super.viewDidLoad()
        chevronLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        datePicker.date = today
        datePicker.maximumDate = today
        print("DatePickerDate on the firstLaunch is \(datePicker.date)")
        initialSetupCollectionView()
        //fetchObject(withDate: today)
        
   
        
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case indexPathOfDatePicker:
            if isDatePickerHidden {
                return 0
            } else {
                return datePicker.frame.height
            }
        case indexPathOfImage:
            return 300
        case indexPathOfDescription:
            return 300
        default:
            return UITableView.automaticDimension
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case indexPathOfDateLabel:
            isDatePickerHidden = !isDatePickerHidden
            tableView.beginUpdates()
            tableView.endUpdates()
            
        default:
            return
        }
    }
    // collectionView setup
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
            print("FetchNasaPod for date: \(date)")
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
        dateArray.removeAll()
        var date: Date!
        if currentDate == today {
            date = today
            for _ in 0...4 {
                dateArray.insert(date, at: 0)
                date = date.yesterday()
            }
        } else {
            date = currentDate
            for _ in 0...4 {
                dateArray.insert(date, at: 0)
                date = date.yesterday()
            }
            date = currentDate.tomorrow()
            for _ in 0...3 {
                if date < today {
                    dateArray.insert(date, at: 0)
                    date = date.tomorrow()
                }
            }
        }
        
        print(dateArray)

        imagesCollectionView.reloadData()
        setContentOffset()


        
    }
    func setContentOffset(){
        let itemsCount = CGFloat((imagesCollectionView?.numberOfItems(inSection: 0))!)
        imagesCollectionView.setContentOffset(CGPoint(x: imagesCollectionView.collectionViewLayout.collectionViewContentSize.width/itemsCount*4, y: 0), animated: false)
    }
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
//        let visibleCell = imagesCollectionView.visibleCells.first!
//        indexPathForVisibleCell = imagesCollectionView.indexPath(for: visibleCell)!
        guard let indexPathOfVisibleCell = indexPathForVisibleCell else {return}
        currentDate = dateArray[indexPathOfVisibleCell.row]
        print("Width of visibleCell is \(imagesCollectionView.cellForItem(at: indexPathForVisibleCell!)?.frame.width)")
        
        
        //imagesCollectionView.reloadItems(at: [indexPathForVisibleCell])
        print("IndexPath for visibleCell is \(indexPathForVisibleCell)")
    }
    func updateTableView(with object: PODObject){
        imageName.text = object.title
        imageDescription.text = object.description
        dateLabel.text = datePicker.date.convertToString()
    }
    func updateImage(imageStringURL: String) -> UIImage? {
        guard let imageURL = URL(string: imageStringURL), let imageData = try? Data(contentsOf: imageURL) else {
            print("Error retreiving image!")
            return nil}
           return UIImage(data: imageData)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let offset = imagesCollectionView.contentOffset
        print(offset)
        let width = imagesCollectionView.bounds.size.width
        
        let index = round(offset.x/width)
        let newOffset: CGPoint = CGPoint(x: index*size.width, y: offset.y)
        coordinator.animate { (context) in
            self.imagesCollectionView.reloadData()
            self.imagesCollectionView.setContentOffset(newOffset, animated: false)
        }

    }

}
