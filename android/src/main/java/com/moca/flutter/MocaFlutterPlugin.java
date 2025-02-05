package com.moca.flutter;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.SharedPreferences;
import android.location.Location;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.preference.PreferenceManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.gson.Gson;
import com.innoquant.moca.MOCA;
import com.innoquant.moca.MOCALogLevel;
import com.innoquant.moca.MOCANavigator;
import com.innoquant.moca.campaigns.action.Action;
import com.innoquant.moca.campaigns.campaign.Experience;
import com.innoquant.moca.config.MOCAConfig;
import com.innoquant.moca.core.MOCAItem;
import com.innoquant.moca.core.MOCAPropertyContainer;
import com.innoquant.moca.core.MOCATag;
import com.innoquant.moca.core.MOCATags;
import com.innoquant.moca.core.MOCAUser;
import com.innoquant.moca.proximity.interfaces.MOCABeacon;
import com.innoquant.moca.proximity.interfaces.MOCAPlace;
import com.innoquant.moca.proximity.interfaces.MOCARegion;
import com.innoquant.moca.proximity.interfaces.MOCARegionGroup;
import com.innoquant.moca.utils.AndroidUtils;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


public class MocaFlutterPlugin implements FlutterPlugin, ActivityAware {

    private static final String TAG = "MocaFlutterPlugin";
    private static MethodChannel channel;
    private static MocaMethodCallHandler callHandler;

    private static final Object lock = new Object();

    @SuppressLint("StaticFieldLeak")
    private static Activity mActivity;
    @SuppressLint("StaticFieldLeak")
    private static Application mContext;

    private static boolean _sdkInitialized;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        Context ctx = binding.getApplicationContext();
        if (ctx instanceof Application) {
            mContext = (Application) ctx;
        } else {
            mContext = (Application) ctx.getApplicationContext();
        }
        channel = new MethodChannel(binding.getBinaryMessenger(), "moca_flutter");
        callHandler = new MocaMethodCallHandler();
        channel.setMethodCallHandler(callHandler);
        // init Moca SDK
        autoInitializeSDK();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        mContext = null;
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        mActivity = null;
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        mActivity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        mActivity = binding.getActivity();
    }

    private static void runOnMainThread(@NonNull Runnable runnable) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(runnable);
    }

    private boolean autoInitializeSDK() {
        try {
            // recover config, if any
            MOCAConfig config = MOCAConfig.getDefault(mContext);
            MOCA.initializeSDK(mContext, config);
            return true;
        } catch (Exception ignored) {
            // no configuration yet
            // ignore and continue
            return false;
        }
    }


    public static class MocaMethodCallHandler implements MethodCallHandler {
        @Override
        public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
            try {
                switch (call.method) {
                    case "initializeSDK":
                        initializeSDK(call, result);
                        break;
                    case "registerBackgroundTask":
                        registerBackgroundTask(call, result);
                        break;
                    case "setLogLevel":
                        setLogLevel(call, result);
                        break;
                    case "initialized":
                        initialized(result);
                        break;
                    case "getVersion":
                        getVersion(result);
                        break;
                    case "getInstanceId":
                        getInstanceId(result);
                        break;
                    case "getLogLevel":
                        getLogLevel(result);
                        break;
                    case "getPermissionsStatus":
                        getPermissionsStatus(result);
                        break;
                    case "geoTrackingEnabled":
                        geoTrackingEnabled(result);
                        break;
                    case "setGeoTrackingEnabled":
                        setGeoTrackingEnabled(call, result);
                        break;
                    case "setUserId":
                        setUserId(call, result);
                        break;
                    case "getUserId":
                        getUserId(result);
                        break;
                    case "eventTrackingEnabled":
                        eventTrackingEnabled(result);
                        break;
                    case "setEventTrackingEnabled":
                        setEventTrackingEnabled(call, result);
                        break;
                    case "flushEvents":
                        flushEvents(call, result);
                        break;
                    case "getQueuedEvents":
                        getQueuedEvents(call, result);
                        break;
                    case "track":
                        track(call, result);
                        break;
                    case "trackViewed":
                        trackViewed(call, result);
                        break;
                    case "addToFavList":
                        addToFavList(call, result);
                        break;
                    case "clearFavList":
                        clearFavList(call, result);
                        break;
                    case "removeFromFavList":
                        removeFromFavList(call, result);
                        break;
                    case "addToWishList":
                        addToWishList(call, result);
                        break;
                    case "removeFromWishList":
                        removeFromWishList(call, result);
                        break;
                    case "clearWishList":
                        clearWishList(call, result);
                        break;
                    case "addToCart":
                        addToCart(call, result);
                        break;
                    case "updateCart":
                        updateCart(call, result);
                        break;
                    case "removeFromCart":
                        removeFromCart(call, result);
                        break;
                    case "clearCart":
                        clearCart(call, result);
                        break;
                    case "beginCheckout":
                        beginCheckout(call, result);
                        break;
                    case "completeCheckout":
                        completeCheckout(call, result);
                        break;
                    case "trackPurchased":
                        trackPurchased(call, result);
                        break;
                    case "trackShared":
                        trackShared(call, result);
                        break;
                    case "trackScreen":
                        trackScreen(call, result);
                        break;
                    case "getLastKnownLocation":
                        getLastKnownLocation(call, result);
                        break;
                    case "addTag":
                        addTag(call, result);
                        break;
                    case "getTags":
                        getTags(call, result);
                        break;
                    case "containsTag":
                        containsTag(call, result);
                        break;
                    case "getTagValue":
                        getTagValue(call, result);
                        break;
                    case "setRemotePushToken":
                        setRemotePushToken(call, result);
                        break;
                    case "setProperty":
                        setProperty(call, result);
                        break;
                    case "setProperties":
                        setProperties(call, result);
                        break;
                    case "getProperty":
                        getProperty(call, result);
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            } catch (Error | Exception e) {
                result.error(e.toString(), e.getMessage(), e.getMessage());
            }
        }

        private void registerBackgroundTask(MethodCall call, Result result) {
            //
            // For this release, do not accept the task
            //
            result.error("Method not supported in this release",
                    "Please contact support@mocaplatform.com", null);
        }
    }

    private static void initializeSDK(MethodCall call, Result result) {
        String appKey = call.argument("appKey");
        String appSecret = call.argument("appSecret");
        if (appKey == null || appSecret == null) {
            result.error("appKey or appSecret is null",
                    "Provide valid appKey and appSecret for this app from Moca account",
                    null);
            return;
        }
        if (MOCA.initialized()) {
            // Already initialized before
            // But we override last key and secret for next execution
            MOCAConfig.setDefaultKeys(mContext, appKey, appSecret);
        } else {
            // Initialize the SDK for the first time
            MOCA.initializeSDK(mContext, appKey, appSecret);
        }
        MocaFlutterReceiver receiver = new MocaFlutterReceiver(channel);
        MOCA.addRegionObserver(receiver);
        MOCA.setCustomActionHandler(receiver);
        MOCA.setCustomNavigator(receiver);
        result.success(true);
    }

    private static void initialized(Result result) {
        result.success(MOCA.initialized());
    }

    private static void getVersion(Result result) {
        result.success(MOCA.getVersion());
    }

    private static void getInstanceId(Result result) {
        result.success(MOCA.getInstance().getId());
    }

    private static void getLogLevel(Result result) {
        result.success(MOCA.getLogLevel().name());
    }

    private static void getPermissionsStatus(Result result) {
        if (AndroidUtils.isBackgroundLocationPermissionGranted(mContext)) {
            result.success("background");
        } else if (AndroidUtils.isForegroundLocationPermissionGranted(mContext)) {
            result.success("foreground");
        } else {
            result.success("denied");
        }
    }

    private static void geoTrackingEnabled(Result result) {
        result.success(MOCA.geoTrackingEnabled());
    }

    private static void eventTrackingEnabled(Result result) {
        result.success(MOCA.eventTrackingEnabled());
    }

    private static void getUserId(Result result) {
        String userId = null;
        if (MOCA.initialized()) {
            MOCAUser user = MOCA.getInstance().getUser();
            if (user != null) {
                userId = user.getId();
            }
        }
        result.success(userId);
    }

    private static void setUserId(MethodCall call, Result result) {
        String userId = call.argument("userId");
        if (!MOCA.initialized()) {
            result.error("Moca SDK not initialized", null, null);
            return;
        }
        MOCAUser user = MOCA.getInstance().getUser();
        if (userId == null) {
            if (user != null) {
                user.logout();
            }
        } else {
            MOCA.getInstance().login(userId);
        }
        result.success(true);
    }

    private static void setGeoTrackingEnabled(MethodCall call, Result result) {
        Boolean enabled = call.argument("enabled");
        if (enabled == null) {
            result.error("enabled is null", null, null);
            return;
        }
        MOCA.setGeoTrackingEnabled(enabled);
        result.success(true);
    }

    private static void setEventTrackingEnabled(MethodCall call, Result result) {
        Boolean enabled = call.argument("enabled");
        if (enabled == null) {
            result.error("enabled is null", null, null);
            return;
        }
        MOCA.setEventTrackingEnabled(enabled);
        result.success(true);
    }

    private static void setLogLevel(MethodCall call, Result result) {
        String logLevel = call.argument("logLevel");
        MOCAConfig config = MOCA.getConfig();
        if (logLevel == null) {
            result.error("logLevel is null",
                    "Use one of the following values: debug, info, warning, error", null);
            return;
        } else if (logLevel.equals("debug")) {
            config.setLogLevel(MOCALogLevel.Debug);
        } else if (logLevel.equals("info")) {
            config.setLogLevel(MOCALogLevel.Info);
        } else if (logLevel.equals("warning")) {
            config.setLogLevel(MOCALogLevel.Warning);
        } else if (logLevel.equals("error")) {
            config.setLogLevel(MOCALogLevel.Error);
        } else {
            result.error("Unsupported logLevel",
                    "Use one of the following values: debug, info, warning, error", null);
            return;
        }
        result.success(true);
    }

    private static void flushEvents(MethodCall call, final Result result) {
        boolean b = MOCA.flushEvents();
        result.success(b);
    }

    private static void getQueuedEvents(MethodCall call, final Result result) {
        Integer count = MOCA.getQueuedEvents();
        result.success(count);
    }

    private static void track(MethodCall call, final Result result) {
        String verb = call.argument("verb");
        if (verb == null) {
            result.error("Verb is null", "Event verb is required", null);
            return;
        }
        String item = call.argument("item");
        if (item != null) {
            String category = call.argument("category");
            if (category != null) {
                Long value = call.argument("value");
                if (value != null) {
                    MOCA.track(verb, category, item, value);
                } else {
                    MOCA.track(verb, category, item);
                }
            } else {
                MOCA.track(verb, item);
            }
        } else {
            Long value = call.argument("value");
            if (value != null) {
                MOCA.track(verb, value);
            } else {
                MOCA.track(verb);
            }
        }
        result.success(true);
    }


    private static void trackViewed(MethodCall call, final Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("Item is null", "Viewed item is required", null);
            return;
        }
        String category = call.argument("category");
        Boolean recommended = call.argument("recommended");
        recommended = recommended != null ? recommended : false;
        if (category != null) {
            MOCA.trackViewed(item, category, recommended);
        } else {
            MOCA.trackViewed(item, recommended);
        }
        result.success(true);
    }

    private static void addToFavList(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("Item is null", "Item is required", null);
            return;
        }
        result.success(MOCA.addToFavList(item));
    }

    private static void removeFromFavList(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("Item is null", "Item is required", null);
            return;
        }
        result.success(MOCA.removeFromFavList(item));
    }

    private static void clearFavList(MethodCall call, Result result) {
        MOCA.clearFavList();
        result.success(true);
    }

    private static void addToWishList(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("Item is null", "Item is required", null);
            return;
        }
        result.success(MOCA.addToWishList(item));
    }

    private static void removeFromWishList(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("Item is null", "Item is required", null);
            return;
        }
        result.success(MOCA.removeFromWishList(item));
    }

    private static void clearWishList(MethodCall call, Result result) {
        MOCA.clearWishList();
        result.success(true);
    }

    private static void addToCart(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("item is null", "Item is required", null);
            return;
        }
        String category = call.argument("category");
        Double unitPrice = call.argument("unitPrice");
        if (unitPrice == null) {
            result.error("unitPrice is null", "unitPrice is required", null);
            return;
        }
        String currency = call.argument("currency");
        if (currency == null) {
            result.error("currency is null", "currency is required", null);
            return;
        }
        Integer quantity = call.argument("quantity");
        if (quantity == null) {
            result.error("quantity is null", "quantity is required", null);
            return;
        } else if (quantity <= 0) {
            result.error("quantity <= 0", "quantity must be positive", null);
            return;
        }
        MOCAItem cartItem = MOCA.createItem(item, category, unitPrice, currency);
        MOCA.addToCart(cartItem, quantity);
        result.success(true);
    }

    private static void updateCart(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("item is null", "Item is required", null);
            return;
        }
        Integer quantity = call.argument("quantity");
        if (quantity == null) {
            result.error("quantity is null", "quantity is required", null);
            return;
        } else if (quantity <= 0) {
            result.error("quantity <= 0", "quantity must be positive", null);
            return;
        }
        MOCA.updateCart(item, quantity);
        result.success(true);
    }

    private static void removeFromCart(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("Item is null", "Item is required", null);
            return;
        }
        result.success(MOCA.removeFromCart(item));
    }

    private static void clearCart(MethodCall call, Result result) {
        MOCA.clearCart();
        result.success(true);
    }

    private static void beginCheckout(MethodCall call, Result result) {
        result.success(MOCA.beginCheckout());
    }

    private static void completeCheckout(MethodCall call, Result result) {
        result.success(MOCA.completeCheckout());
    }


    private static void trackPurchased(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("item is null", "Item is required", null);
            return;
        }
        String category = call.argument("category");
        Double unitPrice = call.argument("unitPrice");
        if (unitPrice == null) {
            result.error("unitPrice is null", "unitPrice is required", null);
            return;
        }
        String currency = call.argument("currency");
        if (currency == null) {
            result.error("currency is null", "currency is required", null);
            return;
        }
        Integer quantity = call.argument("quantity");
        if (quantity == null) {
            result.error("quantity is null", "quantity is required", null);
            return;
        } else if (quantity <= 0) {
            result.error("quantity <= 0", "quantity must be positive", null);
            return;
        }
        MOCAItem cartItem = MOCA.createItem(item, category, unitPrice, currency);
        MOCA.trackPurchased(cartItem, quantity);
        result.success(true);
    }

    private static void trackShared(MethodCall call, Result result) {
        String item = call.argument("item");
        if (item == null) {
            result.error("Item is null", "Item is required", null);
            return;
        }
        result.success(MOCA.trackShared(item));
    }

    private static void trackScreen(MethodCall call, Result result) {
        String screenName = call.argument("screenName");
        if (screenName == null) {
            result.error("screen name is null", "screen name is required", null);
            return;
        }
        MOCA.trackScreenFragment(screenName);
        result.success(true);
    }

    private static void addTag(MethodCall call, Result result) {
        String tag = call.argument("tag");
        if (tag == null) {
            result.error("tag is null", "tag is required", null);
            return;
        }
        String value = call.argument("value");
        if (value != null) {
            MOCA.addTag(tag, value);
        } else {
            MOCA.addTag(tag);
        }
        result.success(true);
    }

    private static void getTags(MethodCall call, Result result) {
        MOCATags tags = MOCA.getTags();
        Iterator<MOCATag> it = tags.iterator();
        HashMap<String, Double> tagsMap = new HashMap<>(tags.size());
        while (it.hasNext()) {
            MOCATag tag = it.next();
            tagsMap.put(tag.getName(), tag.getValue());
        }
        result.success(tagsMap);
    }

    private static void containsTag(MethodCall call, Result result) {
        String tag = call.argument("tag");
        if (tag == null) {
            result.error("tag is null", "tag is required", null);
            return;
        }
        result.success(MOCA.getTags().contains(tag));
    }

    private static void getTagValue(MethodCall call, Result result) {
        String tag = call.argument("tag");
        if (tag == null) {
            result.error("tag is null", "tag is required", null);
            return;
        }
        result.success(MOCA.getTags().getValue(tag));
    }

    private static void getLastKnownLocation(MethodCall call, Result result) {
        Location location = MOCA.getLastKnownLocation();
        if (location == null) {
            result.success(null);
        } else {
            Map<String, Object> map = new HashMap<>();
            map.put("latitude", location.getLatitude());
            map.put("longitude", location.getLongitude());
            map.put("accuracy", location.getAccuracy());
            map.put("provider", location.getProvider());
            result.success(map);
        }
    }

    private static void setRemotePushToken(MethodCall call, Result result) {
        String token = call.argument("token");
        String provider = call.argument("provider");
        if (token == null) {
            result.error("token is null", "token is required", null);
            return;
        }
        if (provider == null) {
            result.error("provider is null", "provider is required", null);
            return;
        }
        MOCA.setRemotePushToken(token, provider);
        result.success(true);
    }

    private static void setProperty(MethodCall call, Result result) {
        String key = call.argument("key");
        Object value = call.argument("value");
        if (key == null) {
            result.error("key is null", "property key is required", null);
            return;
        }
        MOCAUser user = MOCA.getUser();
        if (user != null) {
            user.setProperty(key, value);
        } else {
            MOCA.getInstance().setProperty(key, value);
        }
        result.success(true);
    }


    private static void setProperties(MethodCall call, Result result) {
        HashMap<String, Object> metadataMap = (HashMap<String, Object>)call.arguments;
        MOCAPropertyContainer container = MOCA.getUser() != null ? MOCA.getUser() : MOCA.getInstance();
        for(Map.Entry<String,Object> entry: metadataMap.entrySet()) {
            container.setProperty(entry.getKey(), entry.getValue());
        }
        result.success(true);
    }

    private static void getProperty(MethodCall call, Result result) {
        String key = call.argument("key");
        if (key == null) {
            result.error("key is null", "property key is required", null);
            return;
        }
        MOCAUser user = MOCA.getUser();
        Object value = user != null ? user.getProperty(key) : MOCA.getInstance().getProperty(key);
        result.success(value);
    }

    public static class MocaFlutterReceiver implements MOCARegion.PlaceEventsObserver,
            MOCARegion.BeaconEventsObserver,
            MOCARegion.RegionGroupEventsObserver,
            Action.CustomActionHandler,
            MOCANavigator {
        private final MethodChannel channel;

        MocaFlutterReceiver(MethodChannel channel) {
            this.channel = channel;
        }

        @Override
        public void onEnterPlace(MOCAPlace place) {
            try {
                final List<Object> args = placeToArgs(place);
                synchronized (lock) {
                    runOnMainThread(() -> channel.invokeMethod("onEnterGeofence", args));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onExitPlace(MOCAPlace place) {
            try {
                final List<Object> args = placeToArgs(place);
                synchronized (lock) {
                    runOnMainThread(() -> channel.invokeMethod("onExitGeofence", args));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onEnterBeacon(MOCABeacon beacon) {
            try {
                final List<Object> args = beaconToArgs(beacon);
                synchronized (lock) {
                    runOnMainThread(() -> channel.invokeMethod("onEnterBeacon", args));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onExitBeacon(MOCABeacon beacon) {
            try {
                final List<Object> args = beaconToArgs(beacon);
                synchronized (lock) {
                    runOnMainThread(() -> channel.invokeMethod("onExitBeacon", args));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }


        private List<Object> groupToArgs(MOCARegionGroup group) throws JSONException {
            JSONObject obj = new JSONObject();
            obj.put("name", group.getName());
            obj.put("id", group.getId());
            HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
            final List<Object> args = new ArrayList<>();
            args.add(0);
            args.add(res);
            return args;
        }

        private List<Object> beaconToArgs(MOCABeacon beacon) throws JSONException {
            JSONObject obj = new JSONObject();
            obj.put("name", beacon.getName());
            obj.put("id", beacon.getId());
            obj.put("floor", beacon.getFloor());
            if (beacon.getLocation() != null) {
                obj.put("latitude", beacon.getLocation().getLatitude());
                obj.put("longitude", beacon.getLocation().getLongitude());
            }
            HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
            final List<Object> args = new ArrayList<>();
            args.add(0);
            args.add(res);
            return args;
        }

        private List<Object> placeToArgs(MOCAPlace place) throws JSONException {
            JSONObject obj = new JSONObject();
            obj.put("name", place.getName());
            obj.put("id", place.getId());
            if (place.getGeoFence() != null) {
                obj.put("radius", place.getGeoFence().getRadius());
                obj.put("latitude", place.getGeoFence().getCenter().getLatitude());
                obj.put("longitude", place.getGeoFence().getCenter().getLongitude());
            }
            HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
            final List<Object> args = new ArrayList<>();
            args.add(0);
            args.add(res);
            return args;
        }

        @NonNull
        @Override
        public String getListenerId() {
            return "MocaFlutterListener";
        }

        @Override
        public void onEnterRegionGroup(MOCARegionGroup group) {
            try {
                final List<Object> args = groupToArgs(group);
                synchronized (lock) {
                    runOnMainThread(() -> channel.invokeMethod("onEnterRegionGroup", args));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        @Override
        public void onExitRegionGroup(MOCARegionGroup group) {
            try {
                final List<Object> args = groupToArgs(group);
                synchronized (lock) {
                    runOnMainThread(() -> channel.invokeMethod("onExitRegionGroup", args));
                }
            } catch (Exception e) {
                Log.e(TAG, e.toString());
            }
        }

        private List<Object> toCustomActionArgs(Experience sender, String customAttribute) throws
                JSONException {
            JSONObject obj = new JSONObject();
            obj.put("experience", sender.getName());
            obj.put("campaign", sender.getCampaign().getName());
            obj.put("customAttribute", customAttribute);
            HashMap<String, Object> res = new Gson().fromJson(obj.toString(), HashMap.class);
            final List<Object> args = new ArrayList<>();
            args.add(0);
            args.add(res);
            return args;
        }

        @Override
        public boolean performCustomAction(Experience sender, String customAttribute) {
            try {
                final List<Object> args = toCustomActionArgs(sender, customAttribute);
                synchronized (lock) {
                    runOnMainThread(() -> channel.invokeMethod("onCustomAction", args));
                }
                return true;
            } catch (Exception e) {
                Log.e(TAG, e.toString());
                return false;
            }
        }


        @Override
        public boolean gotoUri(@NonNull Context context, @NonNull Uri uri) {
            // Use a CountDownLatch to block until we get a response (or timeout).
            final CountDownLatch latch = new CountDownLatch(1);
            final boolean[] handled = { false };
            synchronized (lock) {
                runOnMainThread(() -> channel.invokeMethod("gotoUri", uri.toString(), new Result() {
                    @Override
                    public void success(@Nullable Object result) {
                        if (result instanceof Boolean) {
                            handled[0] = (Boolean) result;
                        }
                        latch.countDown();
                    }

                    @Override
                    public void error(@NonNull String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                        latch.countDown();
                    }

                    @Override
                    public void notImplemented() {
                        latch.countDown();
                    }
                }));
            }
            try {
                latch.await(5, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                Log.e(TAG, e.toString());
            }
            return handled[0];
        }

    }

}