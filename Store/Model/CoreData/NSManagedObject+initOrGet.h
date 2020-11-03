//
//  NSManagedObject+initOrGet.h
//  Store
//
//  Created by Philip Dukhov on 11/3/20.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObject (initOrGet)

- (instancetype)initOrGetFirst:(int64_t)id
                       context:(NSManagedObjectContext*)moc;

@end

NS_ASSUME_NONNULL_END
