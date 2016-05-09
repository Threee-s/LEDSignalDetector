//
//  AirImageDetailCollectionViewController.swift
//  LEDSignalDetector
//
//  Created by 文光石 on 2016/04/22.
//  Copyright © 2016年 TrE. All rights reserved.
//

import UIKit


class AirImageDetailCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    let identifierAirImageDetailCell = "AirImageDetailCell"
    let numberOfColumns: CGFloat = 4
    
    var collectionFrames: [CollectionFrame] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirImageDetailCollectionViewController viewDidLoad")
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        // memo:不要(storyboardでIDを指定したから？)
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: identifierAirImageCell)
        
        // Do any additional setup after loading the view.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        print("prepareForSegue[AirImageDetailCollectionViewController]")
        
        print("identifier: \(segue.identifier)")
        
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionFrames.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierAirImageDetailCell, forIndexPath: indexPath) as! AirImageDetailCell
        
        print("cellForItemAtIndexPath")
        
        // Configure the cell
        //let airFile: AirFile = self.airFiles[indexPath.row] as AirFile
        //let fileData: NSData? = self.airFileMan?.getFileData(airFile.filePath)
        //let image: UIImage? = UIImage(data: fileData!)
        let frame: CollectionFrame = self.collectionFrames[indexPath.row] as CollectionFrame
        cell.imageView?.image = nil
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
     return false
     }
     
     override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
     return false
     }
     
     override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
     
     }
     */
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width: CGFloat = (CGRectGetWidth(self.view.frame) - CGFloat(2.0) * CGFloat(numberOfColumns - 1)) / numberOfColumns
        print("width:\(width)")
        
        return CGSizeMake(width, width)
    }

}
