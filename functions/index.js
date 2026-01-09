const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
    try {
        const { userId, title, body, type, relatedId } = data.data;

        // Validate required fields
        if (!userId || !title || !body) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Missing required fields: userId, title, body'
            );
        }

        // Get user's FCM token
        const userDoc = await getFirestore().collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new functions.https.https.HttpsError(
                'not-found',
                'User not found'
            );
        }

        const fcmToken = userDoc.get('fcmToken');
        if (!fcmToken) {
            throw new functions.https.https.https.HttpsError(
                'not-found',
                'FCM token not found for user'
            );
        }

        // Create notification payload
        const notification = {
            notification: {
                title: title,
                body: body,
                sound: 'default',
            },
            data: {
                type: type || 'general',
                relatedId: relatedId || '',
                timestamp: new Date().toISOString(),
            },
            token: fcmToken,
            priority: 'high',
        };

        // Send notification via FCM
        const response = await admin.messaging().send(notification);

        // Save notification to Firestore
        await getFirestore().collection('notifications').add({
            userId,
            title,
            body,
            type: type || 'general',
            relatedId: relatedId,
            data: {},
            createdAt: FieldValue.serverTimestamp(),
            isRead: false,
        });

        return { success: true, messageId: response.messageId };
    } catch (error) {
        console.error('Error sending notification:', error);
        throw new functions.https.https.HttpsError(
            'internal',
            error.message
        );
    }
});

exports.sendMatchNotification = functions.https.onCall(async (data, context) => {
    try {
        const { userId1, userId2 } = data.data;

        if (!userId1 || !userId2) {
            throw new functions.https.https.HttpsError(
                'invalid-argument',
                'Missing required fields: userId1, userId2'
            );
        }

        // Send notifications to both users
        const notification1 = {
            title: '🎉 New Match!',
            body: 'You have a new match! Check out who it is.',
            type: 'new_match',
            relatedId: userId2,
        };

        const notification2 = {
            title: '🎉 New Match!',
            body: 'You have a new match! Check out who it is.',
            type: 'new_match',
            relatedId: userId1,
        };

        // Send to first user
        await sendNotification({
            userId: userId1,
            title: notification1.title,
            body: notification1.body,
            type: notification1.type,
            relatedId: notification1.relatedId,
        });

        // Send to second user
        await sendNotification({
            userId: userId2,
            title: notification2.title,
            body: notification2.body,
            type: notification2.type,
            relatedId: notification2.relatedId,
        });

        return { success: true };
    } catch (error) {
        console.error('Error sending match notification:', error);
        throw new functions.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

exports.sendMessageNotification = functions.https.onCall(async (data, context) => {
    try {
        const { matchId, senderId, receiverId, messageText } = data.data;

        if (!matchId || !senderId || !receiverId || !messageText) {
            throw new functions.https.https.HttpsError(
                'invalid-argument',
                'Missing required fields: matchId, senderId, receiverId, messageText'
            );
        }

        const notification = {
            title: '💬 New Message',
            body: messageText.length > 50
                ? `${messageText.substring(0, 50)}...`
                : messageText,
            type: 'new_message',
            relatedId: matchId,
        };

        await sendNotification({
            userId: receiverId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            relatedId: notification.relatedId,
        });

        return { success: true };
    } catch (error) {
        console.error('Error sending message notification:', error);
        throw new functions.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

exports.sendProfileViewNotification = functions.https.onCall(async (data, context) => {
    try {
        const { profileUserId, viewerId } = data.data;

        if (!profileUserId || !viewerId) {
            throw new functions.https.https.https.https.Error(
                'invalid-argument',
                'Missing required fields: profileUserId, viewerId'
            );
        }

        const notification = {
            title: '👤 Profile View',
            body: 'Someone viewed your profile!',
            type: 'profile_view',
            relatedId: viewerId,
        };

        await sendNotification({
            userId: profileUserId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            relatedId: notification.relatedId,
        });

        return { success: true };
    } catch (error) {
        console.error('Error sending profile view notification:', error);
        throw new functions.https.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

exports.updateUserLocation = functions.https.onCall(async (data, context) => {
    try {
        const { userId, latitude, longitude, accuracy } = data.data;

        if (!userId || latitude == null || longitude == null) {
            throw new functions.https.https.https.https.Error(
                'invalid-argument',
                'Missing required fields: userId, latitude, longitude'
            );
        }

        // Get address from coordinates
        const geocoding = require('geocoding');
        const geocoder = new geocoding.Geocoder();

        const [location] = await geocoder.reverseGeocode({
            lat: latitude,
            lon: longitude,
        });

        const address = location ? {
            street: location.street,
            city: location.city,
            state: location.state,
            country: location.country,
            postalCode: location.postalCode,
        } : {};

        // Update user location in Firestore
        await getFirestore().collection('users').doc(userId).update({
            'location': {
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy || 0,
                timestamp: new Date().toISOString(),
            },
            'address': address,
            'locationUpdatedAt': FieldValue.serverTimestamp(),
        });

        return {
            success: true,
            location: { latitude, longitude, accuracy },
            address
        };
    } catch (error) {
        console.error('Error updating user location:', error);
        throw new functions.https.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

exports.findNearbyUsers = functions.https.onCall(async (data, context) => {
    try {
        const {
            latitude,
            longitude,
            maxDistance,
            minAge,
            maxAge,
            limit = 50,
            excludeUserId
        } = data.data;

        if (latitude == null || longitude == null || maxDistance == null) {
            throw new functions.https.https.https.https.Error(
                'invalid-argument',
                'Missing required fields: latitude, longitude, maxDistance'
            );
        }

        let query = getFirestore()
            .collection('users')
            .where('location.latitude', '!=', null)
            .where('location.longitude', '!=', null)
            .where('isProfileComplete', '==', true);

        // Add age filters if provided
        if (minAge != null) {
            query = query.where('age', '>=', minAge);
        }
        if (maxAge != null) {
            query = query.where('age', '<=', maxAge);
        }

        const snapshot = await query.limit(limit).get();
        const users = [];

        for (const doc of snapshot.docs) {
            if (doc.id === excludeUserId) continue;

            const userLocation = doc.get('location');
            const userLat = userLocation.latitude;
            const userLon = userLocation.longitude;

            // Calculate distance
            const distance = calculateDistance(
                latitude,
                longitude,
                userLat,
                userLon
            );

            if (distance <= maxDistance) {
                users.push({
                    id: doc.id,
                    ...doc.data(),
                    distance: distance,
                });
            }
        }

        // Sort by distance
        users.sort((a, b) => a.distance - b.distance);

        return { success: true, users: users.slice(0, limit) };
    } catch (error) {
        console.error('Error finding nearby users: ', error);
        throw new functions.https.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

exports.createMatch = functions.https.onCall(async (data, context) => {
    try {
        const { userId1, userId2 } = data.data;

        if (!userId1 || !userId2) {
            throw new functions.https.https.https.https.Error(
                'invalid-argument',
                'Missing required fields: userId1, userId2'
            );
        }

        // Create match document
        const matchId = `${userId1}_${userId2}`;

        await getFirestore().collection('matches').doc(matchId).set({
            users: [userId1, userId2],
            createdAt: FieldValue.serverTimestamp(),
            status: 'active',
            lastMessage: null,
            lastMessageTime: null,
        });

        // Update both users' match lists
        await getFirestore().collection('users').doc(userId1).update({
            matches: FieldValue.arrayUnion([userId2]),
        });

        await getFirestore().collection('users').doc(userId2).update({
            matches: FieldValue.arrayUnion([userId1]),
        });

        // Send match notifications
        await sendMatchNotification({
            userId1,
            userId2,
        });

        return {
            success: true,
            matchId
        };
    } catch (error) {
        console.error('Error creating match:', error);
        throw new functions.https.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

// Helper function to calculate distance
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

exports.sendBulkNotifications = functions.https.onCall(async (data, context) => {
    try {
        const { userIds, title, body, type, relatedId } = data.data;

        if (!Array.isArray(userIds) || !title || !body) {
            throw new functions.https.https.Error(
                'invalid-argument',
                'Missing required fields: userIds, title, body'
            );
        }

        const results = [];

        for (const userId of userIds) {
            try {
                const result = await sendNotification({
                    userId,
                    title,
                    body,
                    type,
                    relatedId,
                });
                results.push({ userId, success: true });
            } catch (error) {
                results.push({ userId, success: false, error: error.message });
            }
        }

        return { success: true, results: results };
    } catch (error) {
        console.error('Error sending bulk notifications:', error);
        throw new functions.https.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

exports.getUserStats = functions.https.onCall(async (data, context) => {
    try {
        const { userId } = data.data;

        if (!userId) {
            throw new functions.https.https.https.https.https.Error(
                'invalid-argument',
                'Missing required field: userId'
            );
        }

        const userDoc = await getFirestore().collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new functions.https.https.https.https.https.https.Error(
                'not-found',
                'User not found'
            );
        }

        const userData = userDoc.data();

        // Get match count
        const matches = userData.matches || [];

        // Get message count
        const messagesSnapshot = await getFirestore()
            .collection('matches')
            .where('users', 'array-contains', userId)
            .get();

        let messageCount = 0;
        for (const doc of messagesSnapshot.docs) {
            const messagesCollection = await getFirestore()
                .collection('matches')
                .doc(doc.id)
                .collection('messages')
                .get();
            messageCount += messagesCollection.size();
        }

        // Get unread notifications count
        const unreadNotifications = await getFirestore()
            .collection('notifications')
            .where('userId', '==', userId)
            .where('isRead', '==', false)
            .get();

        return {
            success: true,
            stats: {
                matches: matches.length,
                messages: messageCount,
                unreadNotifications: unreadNotifications.size(),
                profileComplete: userData.isProfileComplete || false,
                lastActivity: userData.lastActivity?.toDate?.toISOString(),
                createdAt: userData.createdAt?.toDate?.toISOString(),
            }
        };
    } catch (error) {
        console.error('Error getting user stats:', error);
        throw new functions.https.https.https.https.https.Error(
            'internal',
            error.message
        );
    }
});

exports.cleanupOldNotifications = functions.https.onRequest(async (req, res) => {
    if (req.method !== 'DELETE') {
        res.status(405).send('Method not allowed');
        return;
    }

    try {
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

        const oldNotifications = await getFirestore()
            .collection('notifications')
            .where('createdAt', '<', thirtyDaysAgo)
            .get();

        const batch = getFirestore().batch();

        for (const doc of oldNotifications.docs) {
            batch.delete(doc.ref);
        }

        await batch.commit();

        res.status(200).json({
            success: true,
            deleted: oldNotifications.size()
        });
    } catch (error) {
        console.error('Error cleaning up old notifications:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});
