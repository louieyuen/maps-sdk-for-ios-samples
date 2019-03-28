/*
 * Copyright 2016 Google Inc. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "GoogleMapsDemos/Samples/BasicMapViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@interface BasicMapViewController () <GMSMapViewDelegate>
@end

@implementation BasicMapViewController {
  UILabel *_statusLabel;
}

- (void)viewDidLoad {
  [super viewDidLoad];
    
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:43.65435
                                                            longitude:-79.4262802
                                                                 zoom:20];
    
  GMSMapView *view = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  view.delegate = self;
  self.view = view;

    // Start loading custom map overlay
    [self parseJSONData];
    
  // Add status label, initially hidden.
  _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
  _statusLabel.alpha = 0.0f;
  _statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  _statusLabel.backgroundColor = [UIColor blueColor];
  _statusLabel.textColor = [UIColor whiteColor];
  _statusLabel.textAlignment = NSTextAlignmentCenter;

  [view addSubview:_statusLabel];
}

- (void)parseJSONData {
    NSURL *dataPath = [[NSBundle mainBundle] URLForResource:@"geojson" withExtension:@"json"];
    NSString *stringPath = [dataPath absoluteString];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:NULL];
    
    [self renderMapWithDict:jsonDict];
}

- (void)renderMapWithDict:(NSDictionary *)jsonDict {
    NSMutableArray *featuresArray = jsonDict[@"features"];
    for (NSDictionary *feature in featuresArray) {
        NSDictionary *geometry = feature[@"geometry"];
        NSString *shape = geometry[@"type"];
        if ([shape isEqualToString:@"Polygon"]) {
            // Grab the coordinates of it
            NSArray *coordinates = geometry[@"coordinates"];
            if (coordinates.count > 0) {
                [self renderPolygon:coordinates];
            }
        }
    }
}

- (void)renderPolygon:(NSArray *)coordinates {
    NSArray <GMSPath*>* paths = [self pathArrayFromCoordinatesArray:coordinates];
    GMSPath *outerBoundaries = paths.firstObject;
    NSArray *innerBoundaries = [[NSArray alloc] init];
    if (paths.count > 1) {
        innerBoundaries =
        [paths subarrayWithRange:NSMakeRange(1, paths.count - 1)];
    }
    NSMutableArray<GMSPath *> *holes = [[NSMutableArray alloc] init];
    for (GMSPath *hole in innerBoundaries) {
        [holes addObject:hole];
    }
    GMSPolygon *poly = [GMSPolygon polygonWithPath:outerBoundaries];
    if (holes.count) {
        poly.holes = holes;
    }
    poly.map = (GMSMapView *)self.view;
}

- (NSArray<GMSPath *> *)pathArrayFromCoordinatesArray:(NSArray<NSArray *> *)coordinates {
    NSMutableArray<GMSPath *> *parsedPaths = [[NSMutableArray alloc] init];
    for (NSArray<NSArray *> *coordinateArray in coordinates) {
        [parsedPaths addObject:[self pathFromCoordinateArray:coordinateArray]];
    }
    return parsedPaths;
}

- (GMSPath *)pathFromCoordinateArray:(NSArray<NSArray *> *)coordinates {
    GMSMutablePath *path = [[GMSMutablePath alloc] init];
    for (NSArray *coordinate in coordinates) {
        [path addCoordinate:[self locationFromCoordinate:coordinate].coordinate];
    }
    return path;
}

- (CLLocation *)locationFromCoordinate:(NSArray *)coordinate {
    return [[CLLocation alloc] initWithLatitude:[coordinate[1] doubleValue]
                                      longitude:[coordinate[0] doubleValue]];
}

- (void)mapViewDidStartTileRendering:(GMSMapView *)mapView {
  _statusLabel.alpha = 0.8f;
  _statusLabel.text = @"Rendering";
}

- (void)mapViewDidFinishTileRendering:(GMSMapView *)mapView {
  _statusLabel.alpha = 0.0f;
}

@end
