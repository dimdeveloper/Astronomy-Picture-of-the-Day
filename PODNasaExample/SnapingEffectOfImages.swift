//
//  SnapingEffectOfImages.swift
//  PODNasaExampleCopy
//
//  Created by TheMacUser on 01.04.2021.
//

import Foundation
import  UIKit
class SnappingFlowLayout: UICollectionViewFlowLayout {
    var firstSetupDone = false
    override func prepare() {
        super.prepare()
        if !firstSetupDone {
            print(firstSetupDone)
                   setup()
                   firstSetupDone = true
                }
            
      
    }
    
    private func setup() {
        print("FirstSetup!")
        let itemsCount = CGFloat((collectionView?.numberOfItems(inSection: 0))!)
        print("itemsCount is \(itemsCount)")
        scrollDirection = .horizontal
        itemSize = CGSize(width: collectionView!.bounds.width, height: collectionView!.bounds.height)
        print("itemsize is \(itemSize)")
        collectionView!.decelerationRate = UIScrollView.DecelerationRate.fast
        print("collectionViewContentSize is \(collectionView?.collectionViewLayout.collectionViewContentSize)")
        guard let collectionView = collectionView else {return}
        print("There is collectionView!")
        print(collectionView.numberOfItems(inSection: 0))
        collectionView.setContentOffset(CGPoint(x: collectionView.collectionViewLayout.collectionViewContentSize.width/itemsCount*4, y: 0), animated: false)
    }
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let layoutAttributes = layoutAttributesForElements(in: collectionView!.bounds)
        let centerOffset = collectionView!.bounds.size.width / 2
        let offsetWithCenter = proposedContentOffset.x + centerOffset
        
        let closesAtribute = layoutAttributes!.sorted { abs($0.center.x - offsetWithCenter) < abs($1.center.x - offsetWithCenter)}.first ?? UICollectionViewLayoutAttributes()
        
        return CGPoint(x: closesAtribute.center.x - centerOffset, y: 0)
    }
    
     
//    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
//        let layoutAttributes = layoutAttributesForElements(in: collectionView!.bounds)
//        let collectionVewItems = collectionView.cont
//    }
}

