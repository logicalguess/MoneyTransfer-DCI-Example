//
//  DCIWithdrawMoneyContext.m
//  Money Transfer DCI
//
//  Created by Martin Pilkington on 09/05/2012.
//  Copyright (c) 2012 M Cubed Software. All rights reserved.
//

#import "M3WithdrawMoneyContext.h"
#import "M3OverdraftAccount.h"
#import "M3ErrorFactory.h"

@protocol M3WithdrawlSource <NSObject>

- (BOOL)withdrawAmount:(NSUInteger)aAmount error:(NSError **)aError;

@end



@implementation M3WithdrawMoneyContext {
	M3Account<M3WithdrawlSource> *sourceAccount;
}

- (id)initWithSourceAccount:(M3Account *)aSourceAccount {
	if ((self = [super init])) {
		sourceAccount = [self playerFromObject:aSourceAccount forRole:self.sourceAccountRole];
	}
	return self;
}

- (DCIRole *)sourceAccountRole {
	DCIRole *role = [DCIRole roleWithProtocol:@protocol(M3WithdrawlSource)];

	role[@"withdrawAmount:error:"] = ^(M3Account *player, NSUInteger aAmount, NSError **aError) {
		NSArray *allowedAccountTypes = @[ [M3Account class], [M3OverdraftAccount class] ];
		if (![allowedAccountTypes containsObject:player.class]) {
			*aError = [M3ErrorFactory accountDoesntSupportWithdrawlsError];
			return NO;
		}

		if (aAmount > player.availableBalance) {
			*aError = [M3ErrorFactory insufficientFundsErrorWithAvailableBalance:player.availableBalance];
			return NO;
		}
		
		player.balance -= aAmount;
		return YES;
	};

	return role;
}

- (BOOL)withdrawAmount:(NSUInteger)aAmount error:(NSError **)aError {
	__block BOOL success = NO;
	[self execute:^{
		success = [sourceAccount withdrawAmount:aAmount error:&*aError];
	}];
	return success;
}

@end
