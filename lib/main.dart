import 'dart:io';

import 'package:PiliWind/build_config.dart';
import 'package:PiliWind/common/constants.dart';
import 'package:PiliWind/common/widgets/custom_toast.dart';
import 'package:PiliWind/common/widgets/mouse_back.dart';
import 'package:PiliWind/http/init.dart';
import 'package:PiliWind/models/common/theme/theme_color_type.dart';
import 'package:PiliWind/plugin/pl_player/controller.dart';
import 'package:PiliWind/router/app_pages.dart';
import 'package:PiliWind/services/account_service.dart';
import 'package:PiliWind/services/logger.dart';
import 'package:PiliWind/services/service_locator.dart';
import 'package:PiliWind/utils/app_scheme.dart';
import 'package:PiliWind/utils/cache_manage.dart';
import 'package:PiliWind/utils/calc_window_position.dart';
import 'package:PiliWind/utils/date_utils.dart';
import 'package:PiliWind/utils/page_utils.dart';
import 'package:PiliWind/utils/request_utils.dart';
import 'package:PiliWind/utils/storage.dart';
import 'package:PiliWind/utils/storage_key.dart';
import 'package:PiliWind/utils/storage_pref.dart';
import 'package:PiliWind/utils/theme_utils.dart';
import 'package:PiliWind/utils/utils.dart';
import 'package:catcher_2/catcher_2.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart' hide calcWindowPosition;
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 你的原有 import 全部保留...
// import 'package:PiliWind/...';

WebViewEnvironment? webViewEnvironment;

void main() {
  // 1) 先初始化 Flutter 绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 2) 捕获 Flutter 框架层错误（构建/布局/绘制）
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 输出到系统日志（爱思助手能看到）
    // ignore: avoid_print
    print('[PW][FLUTTER ERROR] ${details.exception}\n${details.stack}');
  };

  // 3) 捕获 Dart 同步错误（未被 FlutterError 覆盖的）
  PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('[PW][DART ONERROR] $error\n$stack');
    return true; // 返回 true 表示我们已处理，避免应用直接杀死
  };

  // 4) 最外层兜底：覆盖所有异步 Zone 的未捕获异常
  runZonedGuarded(() async {
    // ========== 你的原 main() 逻辑从这里开始 ==========
    MediaKit.ensureInitialized();
    try {
      await GStorage.init();
    } catch (e, st) {
      // 这类初始化阶段的异常，之前会“溜走”，现在能看到
      // ignore: avoid_print
      print('[PW][BOOT] GStorage init error: $e\n$st');
      await Utils.copyText(e.toString());
      exit(0);
    }

    Get.lazyPut(AccountService.new);
    HttpOverrides.global = _CustomHttpOverrides();
    CacheManage.autoClearCache();

    if (Utils.isMobile) {
      await Future.wait([
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          if (Pref.horizontalScreen) ...[
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        ]),
        setupServiceLocator(),
      ]);
    }

    if (Platform.isWindows) {
      try {
        if (await WebViewEnvironment.getAvailableVersion() != null) {
          final dir = await getApplicationSupportDirectory();
          webViewEnvironment = await WebViewEnvironment.create(
            settings: WebViewEnvironmentSettings(
              userDataFolder: path.join(dir.path, 'flutter_inappwebview'),
            ),
          );
        }
      } catch (e, st) {
        // ignore: avoid_print
        print('[PW][WEBVIEW] create environment error: $e\n$st');
      }
    }

    // 关键业务初始化也打点，便于在爱思里定位走到哪一步崩的
    // ignore: avoid_print
    print('[PW][BOOT] Request init');
    Request();
    Request.setCookie();
    RequestUtils.syncHistoryStatus();
    if (Utils.isMobile) {
      // ignore: avoid_print
      print('[PW][BOOT] Scheme init');
      PiliScheme.init();
    }

    SmartDialog.config.toast = SmartConfigToast(
      displayType: SmartToastType.onlyRefresh,
    );

    if (Utils.isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    } else if (Utils.isDesktop) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = WindowOptions(
        minimumSize: const Size(400, 720),
        skipTaskbar: false,
        titleBarStyle:
            Pref.showWindowTitleBar ? TitleBarStyle.normal : TitleBarStyle.hidden,
        title: Constants.appName,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        final windowSize = Pref.windowSize;
        await windowManager.setBounds(
          await calcWindowPosition(windowSize) & windowSize,
        );
        if (Pref.isWindowMaximized) await windowManager.maximize();
        await windowManager.show();
        await windowManager.focus();
      });
    }

    // 额外：让 ErrorWidget 在 release 下不直接崩（可选）
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // ignore: avoid_print
      print('[PW][ErrorWidget] ${details.exception}\n${details.stack}');
      return const SizedBox.shrink();
    };

    // ========== 仍然保留你原来的 Catcher2 行为 ==========
    if (Pref.enableLog) {
      String buildConfig = '\n'
          'Build Time: ${DateFormatUtils.format(BuildConfig.buildTime, format: DateFormatUtils.longFormatDs)}\n'
          'Commit Hash: ${BuildConfig.commitHash}';
      final Catcher2Options debugConfig = Catcher2Options(
        SilentReportMode(),
        [
          FileHandler(await LoggerUtils.getLogsPath()),
          ConsoleHandler(
            enableDeviceParameters: false,
            enableApplicationParameters: false,
            enableCustomParameters: true,
          ),
        ],
        customParameters: {'BuildConfig': buildConfig},
      );

      final Catcher2Options releaseConfig = Catcher2Options(
        SilentReportMode(),
        [
          FileHandler(await LoggerUtils.getLogsPath()),
          ConsoleHandler(enableCustomParameters: true),
        ],
        customParameters: {'BuildConfig': buildConfig},
      );

      // 这里依然用 Catcher2 包住 runApp
      Catcher2(
        debugConfig: debugConfig,
        releaseConfig: releaseConfig,
        runAppFunction: () {
          // ignore: avoid_print
          print('[PW][BOOT] runApp with Catcher2');
          runApp(const MyApp());
        },
      );
    } else {
      // ignore: avoid_print
      print('[PW][BOOT] runApp (no Catcher2)');
      runApp(const MyApp());
    }
    // ========== 你的原 main() 逻辑到此结束 ==========
  }, (Object error, StackTrace stack) {
    // 最外层兜底，任何漏网之鱼都会到这里
    // ignore: avoid_print
    print('[PW][UNCAUGHT] $error\n$stack');
  });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ThemeData? darkThemeData;

  @override
  Widget build(BuildContext context) {
    Color brandColor = colorThemeTypes[Pref.customColor].color;
    bool isDynamicColor = Pref.dynamicColor;
    FlexSchemeVariant variant = FlexSchemeVariant.values[Pref.schemeVariant];

    // 强制设置高帧率
    if (Platform.isAndroid) {
      late List<DisplayMode> modes;
      FlutterDisplayMode.supported.then((value) {
        modes = value;
        final String? storageDisplay = GStorage.setting.get(
          SettingBoxKey.displayMode,
        );
        DisplayMode? displayMode;
        if (storageDisplay != null) {
          displayMode = modes.firstWhereOrNull(
            (e) => e.toString() == storageDisplay,
          );
        }
        displayMode ??= DisplayMode.auto;
        FlutterDisplayMode.setPreferredMode(displayMode);
      });
    }

    return DynamicColorBuilder(
      builder: ((ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme? lightColorScheme;
        ColorScheme? darkColorScheme;
        if (lightDynamic != null && darkDynamic != null && isDynamicColor) {
          // dynamic取色成功
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // dynamic取色失败，采用品牌色
          lightColorScheme = SeedColorScheme.fromSeeds(
            primaryKey: brandColor,
            brightness: Brightness.light,
            variant: variant,
            // dynamicSchemeVariant: dynamicSchemeVariant,
            // tones: FlexTones.soft(Brightness.light),
          );
          darkColorScheme = SeedColorScheme.fromSeeds(
            primaryKey: brandColor,
            brightness: Brightness.dark,
            variant: variant,
            // dynamicSchemeVariant: dynamicSchemeVariant,
            // tones: FlexTones.soft(Brightness.dark),
          );
        }

        // 图片缓存
        // PaintingBinding.instance.imageCache.maximumSizeBytes = 1000 << 20;
        return GetMaterialApp(
          title: Constants.appName,
          theme: ThemeUtils.getThemeData(
            colorScheme: lightColorScheme,
            isDynamic: lightDynamic != null && isDynamicColor,
            variant: variant,
          ),
          darkTheme: ThemeUtils.getThemeData(
            colorScheme: darkColorScheme,
            isDynamic: darkDynamic != null && isDynamicColor,
            isDark: true,
            variant: variant,
          ),
          themeMode: Pref.themeMode,
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          locale: const Locale("zh", "CN"),
          supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
          fallbackLocale: const Locale("zh", "CN"),
          getPages: Routes.getPages,
          initialRoute: '/',
          builder: FlutterSmartDialog.init(
            toastBuilder: (String msg) => CustomToast(msg: msg),
            loadingBuilder: (msg) => LoadingWidget(msg: msg),
            builder: (context, child) {
              child = MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(Pref.defaultTextScale),
                ),
                child: child!,
              );
              if (Utils.isDesktop) {
                void onBack() {
                  if (SmartDialog.checkExist()) {
                    SmartDialog.dismiss();
                    return;
                  }

                  if (Get.isDialogOpen ?? Get.isBottomSheetOpen ?? false) {
                    Get.back();
                    return;
                  }

                  final plCtr = PlPlayerController.instance;
                  if (plCtr != null) {
                    if (plCtr.isFullScreen.value) {
                      plCtr
                        ..triggerFullScreen(status: false)
                        ..controlsLock.value = false;
                      return;
                    }

                    if (plCtr.isDesktopPip) {
                      plCtr.exitDesktopPip().whenComplete(
                        () => plCtr.initialFocalPoint = Offset.zero,
                      );
                      return;
                    }
                  }

                  Get.back();
                }

                return Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) {
                    if (event.logicalKey == LogicalKeyboardKey.escape &&
                        event is KeyDownEvent) {
                      onBack();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: MouseBackDetector(
                    onTapDown: onBack,
                    child: child,
                  ),
                );
              }
              return child;
            },
          ),
          navigatorObservers: [
            FlutterSmartDialog.observer,
            PageUtils.routeObserver,
          ],
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.unknown,
              if (Utils.isDesktop) PointerDeviceKind.mouse,
            },
          ),
        );
      }),
    );
  }
}

class _CustomHttpOverrides extends HttpOverrides {
  final badCertificateCallback = kDebugMode || Pref.badCertificateCallback;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      // ..maxConnectionsPerHost = 32
      ..idleTimeout = const Duration(seconds: 15);
    if (badCertificateCallback) {
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}
