//
//  RatingControl.swift
//  FoodTracker
//
//  Created by Alexander Fang on 1/30/17.
//  Copyright © 2017 Alex Fang. All rights reserved.
//

import UIKit

@IBDesignable class RatingControl: UIStackView {
    // MARK: Properties
    // contains list of buttons
    private var ratingButtons = [UIButton]()
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        // property observers -- called every time a property's value is set (after)
        didSet {
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }
    
    // accessabile from any other class in app
    var rating = 0
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    // MARK: Button Action
    func ratingButtonTapped(button: UIButton) {
        print("Button pressed 👍")
    }
    
    
    // MARK: Private Methods
    private func setupButtons() {
        // clear any existing buttons
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        ratingButtons.removeAll()
        
        for _ in 0..<starCount {
            // Create the button
            let button = UIButton()
            button.backgroundColor = UIColor.red
            
            // Add constraints (define button as fixed-sized object in layout (44 pt x 44 pt)
            // Disables button's automaticlaly generated constraints (default is true)
            button.translatesAutoresizingMaskIntoConstraints = false
            // width and height anchor give access to layout anchors used to create constraints
            // isActive activates/deactivates it
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            
            // Setup the button action
            button.addTarget(self, action: #selector(RatingControl.ratingButtonTapped(button:)), for: .touchUpInside)
            
            // Add button to stack
            // adds to list of views managed by RatingControl stack view
            addArrangedSubview(button)
            
            // Add the new button to the rating button array
            ratingButtons.append(button)
        }
    }


}
