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
                   setup()
                   firstSetupDone = true
                }
    }
    
    private func setup() {
        let itemsCount = CGFloat((collectionView?.numberOfItems(inSection: 0))!)
        scrollDirection = .horizontal
        itemSize = CGSize(width: collectionView!.bounds.width, height: collectionView!.bounds.height)
        print(itemSize)
        print(self.collectionViewContentSize)
        collectionView!.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView!.setContentOffset(CGPoint(x: collectionView!.collectionViewLayout.collectionViewContentSize.width/itemsCount * (itemsCount - 1), y: 0), animated: false)
    }
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let layoutAttributes = layoutAttributesForElements(in: collectionView!.bounds)
        let centerOffset = collectionView!.bounds.size.width / 2
        let offsetWithCenter = proposedContentOffset.x + centerOffset
        let closesAtribute = layoutAttributes!.sorted { abs($0.center.x - offsetWithCenter) < abs($1.center.x - offsetWithCenter)}.first ?? UICollectionViewLayoutAttributes()
        
        return CGPoint(x: closesAtribute.center.x - centerOffset, y: 0)
    }
}

