//
//  NSManagedObject+initOrGet.m
//  Store
//
//  Created by Philip Dukhov on 11/3/20.
//

#import "NSManagedObject+initOrGet.h"

@implementation NSManagedObject (initOrGet)

- (instancetype)initOrGetFirst:(int64_t)id
                       context:(NSManagedObjectContext*)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(self.class).pathExtension];
    request.predicate = [NSPredicate predicateWithFormat:@"id == %@", @(id)];
    request.fetchLimit = 1;
    NSError *error;
    NSManagedObject *result = [moc executeFetchRequest:request error:&error].firstObject;
    if (result != nil) {
        return result;
    }
    self = [self initWithContext:moc];
    [self setValue:@(id) forKey:@"id"];
    return self;
}

@end
