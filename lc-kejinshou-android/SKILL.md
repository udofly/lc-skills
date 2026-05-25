---
name: lc-kejinshou-android
description: 氪金兽 Android 原生项目编码规范。在 kejinshou_android 项目中开发、重构或审查代码时必须应用此技能。当工作目录为 kejinshou_android 且涉及 Activity、Fragment、网络请求、自定义 View、工具类等编码时自动触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "1.0"
  project: kejinshou_android
---

# 氪金兽 Android 原生编码规范

本技能定义了 `kejinshou_android` 项目的完整编码规范，适用于所有新增和修改的代码。

---

## 项目概况

- **项目名**: 氪金兽 Android（kejinshou_android）
- **包名**: `com.kejinshou.krypton`
- **技术栈**: Java + Android SDK 30 + OkHttp + GreenDAO + Butterknife + EventBus + Glide
- **构建工具**: Gradle 7.1.2（AGP），Java 11 编译
- **最低支持**: minSdkVersion 20，targetSdkVersion 30
- **架构模式**: 单模块、Activity/Fragment 直接调用网络层（无 ViewModel/MVP 框架）
- **多渠道打包**: 11 个 flavor（app_test + 10 个生产渠道）

---

## 1. 目录结构

```
app/src/main/java/com/kejinshou/krypton/
├── adapter/        # RecyclerView/ListView 适配器（Adapter*）
├── base/           # 基类（BaseActivity, BaseFragment, LxApplication, ActivityContainer, CrashHandler）
├── bean/           # 数据模型（IEvent 等简单 POJO）
├── constains/      # 常量类（WebUrl, LxKeys, JsonConstants）⚠ 注意拼写：constains
├── dialog/         # 对话框与弹窗（Dialog*, Pop*）
├── download/       # 下载工具
├── interfaces/     # 回调接口定义
├── network/        # 网络层（OkRequest, HttpUtil, HttpInterface, CommonRequest, LxRequest）
├── push/           # 推送集成（阿里云推送 + 多厂商通道）
├── sqlite/         # GreenDAO 数据库层（GreenDaoManager, DaoMaster, DaoSession）
├── ui/             # 功能页面（按业务模块分子目录）
│   ├── main/       # 首页（MainActivity, FragmentHome）
│   ├── goods/      # 商品（GoodsDetailActivity, FragmentGoods）
│   ├── my/         # 我的（FragmentMy, 设置、钱包等）
│   ├── pay/        # 支付（PayActivity, PayUtils）
│   ├── message/    # 消息
│   ├── order/      # 订单
│   ├── game/       # 游戏相关
│   ├── estimate/   # 鉴定
│   ├── video/      # 视频
│   └── demo/       # 演示/实验功能
├── utils/          # 工具类（65+ 个，LxUtils, KjsUtils, JsonUtils, DateUtil 等）
├── widget/         # 自定义 View（38+ 个，LXRoundImageView, CustomBanner 等）
└── wxapi/          # 微信开放平台回调
```

**资源目录**:
```
app/src/main/res/
├── layout/         # XML 布局文件
├── drawable*/      # 图片资源（hdpi/xhdpi/xxhdpi/xxxhdpi）
├── values/         # 字符串、颜色、尺寸、样式
└── ...
```

---

## 2. 基类规范

### 2.1 BaseActivity

所有 Activity 必须继承 `BaseActivity`（extends `FragmentActivity`）：

```java
public class XxxActivity extends BaseActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_xxx);
        ButterKnife.bind(this);
        // 初始化逻辑
    }
}
```

**BaseActivity 提供的能力**:
- `mContext` — 当前 Context 引用
- `intentBase` — 启动 Intent（用于获取传参）
- `weak` — WeakReference 防内存泄漏
- ActionBar 管理（`initActionbar()`、`setTitle()`）
- Activity 栈管理（`ActivityContainer`）
- 状态栏颜色设置（`StatusBarUtil`）
- 强制竖屏（Android O 除外）

### 2.2 BaseFragment

所有 Fragment 必须继承 `BaseFragment`（extends `Fragment`）：

```java
public class FragmentXxx extends BaseFragment {
    // 提供多个 startActivity 重载方法
    // 提供 mContext 上下文
}
```

### 2.3 LxApplication

Application 单例，通过 `LxApplication.getInstance()` 获取全局 Context。

---

## 3. 命名规范

### 3.1 类命名

| 类型 | 命名模式 | 示例 |
|------|----------|------|
| Activity | `*Activity` | `PayActivity`, `GoodsDetailActivity`, `WelcomeActivity` |
| Fragment | `Fragment*` | `FragmentHome`, `FragmentGoods`, `FragmentMy` |
| Adapter | `Adapter*` | `AdapterGoodsList`, `AdapterBankList`, `AdapterOrderList` |
| Dialog/弹窗 | `Dialog*` 或 `Pop*` | `DialogUpgrade`, `PopProgress`, `PopSellWay` |
| 工具类 | `*Utils` 或 `*Util` | `LxUtils`, `DateUtil`, `JsonUtils`, `ViewUtils` |
| 自定义 View | 描述性名称 | `LXRoundImageView`, `CustomBanner`, `FlowLayout` |
| 管理器 | `*Manager` | `GreenDaoManager` |
| 常量类 | 描述性名称 | `WebUrl`, `LxKeys`, `JsonConstants` |

### 3.2 变量命名

```java
// 成员变量：使用有意义的名称（项目不强制 m 前缀，但 BaseActivity 中使用了 mContext）
public Context mContext;
private TextView tvTitle;
private ImageView btnLeft;

// 常量：全大写 + 下划线
public static final String BizType_GOODS_BUY = "1";
public static final String GAME_TYPE_NORMAL = "normal";
public static final int REQUEST_CORD_AVATAR = 100;
public static final int WHAT_LOAD_SUCCESS = 1;

// SP Key：SP_ 前缀
public static String SP_MW_H5_TOKEN = "SP_MW_H5_TOKEN";
public static String SP_GAME_SERVER_LIST = "SP_GAME_SERVER_LIST_";
```

### 3.3 资源命名

```
布局文件:    activity_xxx.xml / fragment_xxx.xml / item_xxx.xml / dialog_xxx.xml
控件 ID:     tv_title / btn_submit / iv_avatar / rv_list / et_search
图片资源:    ic_xxx / bg_xxx / btn_xxx
```

---

## 4. 视图绑定

项目使用 **Butterknife** 进行视图绑定和点击事件：

```java
// 视图绑定
@BindView(R.id.tv_title)
TextView tvTitle;

@BindView(R.id.rv_list)
RecyclerView rvList;

// 点击事件
@OnClick(R.id.btn_submit)
void onSubmitClick() {
    // 处理点击
}

// 在 onCreate 中初始化
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_xxx);
    ButterKnife.bind(this);
}
```

> **注意**: DataBinding 已在 build.gradle 中启用，但项目主要使用 Butterknife。新代码保持一致使用 Butterknife。

---

## 5. 网络请求规范

### 5.1 请求架构

```
Activity/Fragment
  → OkRequest.getInstance().request(context, api, params, callback)
  → HttpUtil 构建请求头和签名
  → OkHttp 发送请求
  → 回调到主线程
```

### 5.2 API 路径定义

API 路径以字符串常量定义，格式为 `mwp.kjs_{module}.{feature}.{action}`：

```java
// 在常量类或使用处直接定义
String api = "mwp.kjs_trade.order.create";
String api = "mwp.kjs_product.goods.list";
String api = "mwp.kjs_user.info.get";
```

### 5.3 发起请求

```java
// 方式一：仅关心外层成功（MWP 网关层）
OkRequest.getInstance().request(mContext, api, params, new HttpInterface.onMwpSuccess() {
    @Override
    public void mwpSuccess(JSONObject data) {
        // data 为 MWP 网关返回的外层数据
    }
});

// 方式二：关心业务层成功（KJS 业务层，status=0）
OkRequest.getInstance().request(mContext, api, params, new HttpInterface.onKjsSuccess() {
    @Override
    public void kjsSuccess(JSONObject data) {
        // data 为业务数据（已校验 status=0）
    }
});

// 方式三：获取完整响应
OkRequest.getInstance().request(mContext, api, params, new HttpInterface.onResult() {
    @Override
    public void result(JSONObject data) {
        // data 为完整响应，需自行判断状态
    }
});

// 方式四：数组响应
OkRequest.getInstance().request(mContext, api, params, new HttpInterface.onResultArray() {
    @Override
    public void resultArray(JSONArray data) {
        // data 为 JSONArray
    }
});
```

### 5.4 请求参数构建

```java
JSONObject params = new JSONObject();
params.put("goods_id", goodsId);
params.put("page", page);
params.put("page_size", 20);
OkRequest.getInstance().request(mContext, api, params, callback);
```

### 5.5 环境切换

```java
// WebUrl.java
// 测试环境
WebUrl.BASE_URL_MWP_TEST = "https://kjs-api.kr36.net";
// 生产环境
WebUrl.BASE_URL_MWP_WWW  = "https://api.kejinshou.com";

// 通过 flavor 自动切换（app_test vs 生产渠道）
```

---

## 6. JSON 处理

项目使用 **FastJSON2** 作为主要 JSON 库：

```java
import com.alibaba.fastjson2.JSONObject;
import com.alibaba.fastjson2.JSONArray;

// 创建 JSON 对象
JSONObject params = new JSONObject();
params.put("key", "value");

// 解析字段
String name = data.getString("name");
int count = data.getIntValue("count");
JSONArray list = data.getJSONArray("list");
JSONObject item = data.getJSONObject("detail");

// 安全取值（避免 NPE）
String value = data.getString("key");  // 返回 null 而非抛异常
```

> **注意**: 项目同时引入了 FastJSON 1.x（`com.alibaba.fastjson`）和 Gson，但新代码统一使用 `com.alibaba.fastjson2`。

---

## 7. 事件通信（EventBus）

项目使用 **greenrobot EventBus** 进行组件间通信：

```java
// 定义事件（使用 IEvent 或自定义事件类）
// IEvent 是项目通用事件载体

// 发送事件
EventBus.getDefault().post(new IEvent("event_type", data));

// 注册/注销（在 Activity/Fragment 中）
@Override
protected void onStart() {
    super.onStart();
    EventBus.getDefault().register(this);
}

@Override
protected void onStop() {
    super.onStop();
    EventBus.getDefault().unregister(this);
}

// 接收事件
@Subscribe(threadMode = ThreadMode.MAIN)
public void onEvent(IEvent event) {
    if ("event_type".equals(event.getType())) {
        // 处理事件
    }
}
```

---

## 8. 本地存储

### 8.1 SharedPreferences

```java
// 存储
SharedPreferencesUtil.putString(context, "key", "value");
SharedPreferencesUtil.putInt(context, "key", 123);
SharedPreferencesUtil.putBoolean(context, "key", true);

// 读取
String value = SharedPreferencesUtil.getString(context, "key", "default");
int num = SharedPreferencesUtil.getInt(context, "key", 0);
boolean flag = SharedPreferencesUtil.getBoolean(context, "key", false);
```

### 8.2 GreenDAO（SQLite ORM）

```java
// 获取管理器
GreenDaoManager manager = GreenDaoManager.getInstance();

// 操作示例（GoodsFilter 搜索历史、GameProperty 游戏属性）
manager.insertGoodsFilter(new GoodsFilter(keyword));
List<GoodsFilter> history = manager.queryAllGoodsFilter();
manager.deleteGoodsFilter(filter);
```

---

## 9. 图片加载

统一使用 **Glide** 加载图片：

```java
// 基础加载
Glide.with(context)
    .load(imageUrl)
    .into(imageView);

// 带占位图和错误图
Glide.with(context)
    .load(imageUrl)
    .placeholder(R.drawable.default_placeholder)
    .error(R.drawable.default_error)
    .into(imageView);

// 项目工具方法（LxUtils 中封装）
LxUtils.loadImage(context, imageUrl, imageView);
```

> 项目集成了 WebP 支持和自定义 `GlideEngine`。

---

## 10. 列表与适配器

### 10.1 RecyclerView 适配器

```java
public class AdapterXxxList extends RecyclerView.Adapter<AdapterXxxList.ViewHolder> {

    private Context context;
    private List<JSONObject> dataList;

    public AdapterXxxList(Context context, List<JSONObject> dataList) {
        this.context = context;
        this.dataList = dataList;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_xxx, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        JSONObject item = dataList.get(position);
        holder.tvName.setText(item.getString("name"));
    }

    @Override
    public int getItemCount() {
        return dataList == null ? 0 : dataList.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        @BindView(R.id.tv_name) TextView tvName;

        ViewHolder(View itemView) {
            super(itemView);
            ButterKnife.bind(this, itemView);
        }
    }
}
```

### 10.2 下拉刷新

项目使用 **SmartRefreshLayout**：

```java
// XML 布局
<com.scwang.smart.refresh.layout.SmartRefreshLayout
    android:id="@+id/refreshLayout"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <RecyclerView
        android:id="@+id/rv_list"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

</com.scwang.smart.refresh.layout.SmartRefreshLayout>

// Java 设置
refreshLayout.setOnRefreshListener(refreshLayout -> {
    page = 1;
    loadData();
});
refreshLayout.setOnLoadMoreListener(refreshLayout -> {
    page++;
    loadData();
});
// 结束刷新
refreshLayout.finishRefresh();
refreshLayout.finishLoadMore();
refreshLayout.finishLoadMoreWithNoMoreData(); // 没有更多数据
```

---

## 11. 页面导航

### 11.1 Activity 跳转

```java
// 无参跳转
Intent intent = new Intent(mContext, TargetActivity.class);
startActivity(intent);

// 带参跳转
Intent intent = new Intent(mContext, GoodsDetailActivity.class);
intent.putExtra("goods_id", goodsId);
intent.putExtra("goods_name", goodsName);
startActivity(intent);

// 获取参数
String goodsId = intentBase.getStringExtra("goods_id");
// 或
String goodsId = getIntent().getStringExtra("goods_id");

// startActivityForResult
startActivityForResult(intent, REQUEST_CODE);

@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    if (requestCode == REQUEST_CODE && resultCode == RESULT_OK) {
        // 处理返回结果
    }
}
```

### 11.2 Fragment 切换

```java
// MainActivity 中通过 TabLayout 管理 Fragment
// 手动切换 Fragment
getSupportFragmentManager()
    .beginTransaction()
    .replace(R.id.container, fragment)
    .commit();
```

---

## 12. 多渠道打包

### 12.1 Flavor 配置

| Flavor | 渠道码 | 用途 |
|--------|--------|------|
| `app_test` | test | 测试环境 |
| `kejinshou` | kejinshou | 基础生产包 |
| `kejinshou_vivo` | vivocpd | vivo 应用商店 |
| `kejinshou_oppo` | oppocpd | OPPO 应用商店 |
| `kejinshou_mi` | micpd | 小米应用商店 |
| `kejinshou_huawei` | huaweicpd | 华为应用商店 |
| `kejinshou_honor` | honorcpd | 荣耀应用商店 |
| `kejinshou_baidu` | baiducpd | 百度 |
| `kejinshou_kuaishou` | kuaishoucpd | 快手 |
| `kejinshou_organic_yingyongbao` | organic_yingyongbao | 应用宝（自然量） |

### 12.2 Manifest 占位符

每个 flavor 通过 `manifestPlaceholders` 配置差异化参数：
- `APP_NAME` — 应用名称
- `SCHEME` — Deep Link Scheme
- `QQ_APPID` — QQ AppID
- `CHANNEL` — 渠道码
- `OPEN_INSTALL_KEY` — OpenInstall AppKey
- `ALI_PUSH_APPKEY` / `ALI_PUSH_APPSECRET` — 阿里云推送

### 12.3 环境判断

```java
// 判断是否测试环境
if (LxKeys.FLAVOR_TEST.equals(BuildConfig.FLAVOR)) {
    // 测试环境逻辑
}
```

---

## 13. 第三方 SDK 集成

### 13.1 支付

| SDK | 用途 |
|-----|------|
| 支付宝 SDK | 支付宝支付 |
| 微信 SDK 6.8.0 | 微信支付 + 分享 |
| 京东支付 SDK | 京东支付 |

支付统一通过 `PayUtils` 处理。

### 13.2 推送

- **阿里云推送 3.8.8.1**（主通道）
- 多厂商辅助通道：华为、小米、OPPO、vivo
- 统一通过 `PushUtils` 管理

### 13.3 分享

- **友盟分享 7.3.2**（微信、QQ、新浪微博）
- 通过 `TjUtils` 封装

### 13.4 监控

- **Sentry 7.10.0** — 崩溃和异常监控
- **友盟统计 9.5.6** — 用户行为分析

---

## 14. 常用工具类速查

| 工具类 | 用途 | 关键方法 |
|--------|------|----------|
| `LxUtils` | 核心工具 | 图片加载、Intent 参数、设备信息 |
| `KjsUtils` | 业务工具 | CDN 图片处理、OSS 操作 |
| `JsonUtils` | JSON 操作 | 解析、取值、转换 |
| `DateUtil` | 日期时间 | 格式化、计算 |
| `ViewUtils` | 视图尺寸 | dp/px 转换、屏幕尺寸 |
| `FileUtils` | 文件操作 | 读写、路径处理 |
| `StringUtil` | 字符串 | 空判断、格式化 |
| `SharedPreferencesUtil` | SP 存储 | 读写 SharedPreferences |
| `StatusBarUtil` | 状态栏 | 颜色、文字色、沉浸式 |
| `ClickUtils` | 防抖点击 | 防止重复点击 |
| `CountDownUtils` | 倒计时 | 验证码倒计时等 |
| `CameraUtils` | 相机拍照 | 拍照、相册选取 |
| `EncryptUtils` | 加密 | MD5 签名 |

---

## 15. 禁止事项

- **禁止**使用 Jetpack Compose（项目为纯 XML 布局）
- **禁止**使用 Kotlin 协程做网络请求（项目网络层基于 OkHttp 回调）
- **禁止**使用 Hilt/Dagger 等 DI 框架（项目使用手动单例）
- **禁止**使用 Jetpack Navigation（项目使用 Intent 跳转）
- **禁止**使用 `com.alibaba.fastjson.JSONObject`（旧版），统一用 `com.alibaba.fastjson2.JSONObject`
- **禁止**使用 `import _` 通配符导入
- **禁止**在非 UI 线程直接操作 View
- **禁止**在 Activity/Fragment 中硬编码 API 路径字符串（应定义为常量）
- **禁止**直接 `new OkHttpClient()`（使用 `OkRequest.getInstance()`）
- **禁止**在 ProGuard 规则中移除第三方 SDK 的 keep 规则

---

## 16. 新增页面模板

### 16.1 新增 Activity 检查清单

1. 创建布局文件 `res/layout/activity_xxx.xml`
2. 创建 Activity 类继承 `BaseActivity`
3. 在 `AndroidManifest.xml` 中注册
4. 使用 `ButterKnife.bind(this)` 绑定视图
5. 如有列表，配置 `SmartRefreshLayout` + `RecyclerView`
6. 网络请求使用 `OkRequest.getInstance().request()`
7. 页面间传参使用 `Intent.putExtra()` + `intentBase.getStringExtra()`

### 16.2 新增 Fragment 检查清单

1. 创建布局文件 `res/layout/fragment_xxx.xml`
2. 创建 Fragment 类继承 `BaseFragment`
3. 在 `onCreateView` 中 inflate 布局并 `ButterKnife.bind(this, view)`
4. 如需 EventBus，在 `onStart/onStop` 中注册/注销

---

## 17. 构建与调试

### 17.1 构建命令

```bash
# 测试包
./gradlew assembleApp_testDebug

# 生产包（以 kejinshou 为例）
./gradlew assembleKejinshouRelease

# 所有渠道 Release
./gradlew assembleRelease
```

### 17.2 APK 输出

APK 命名格式：`氪金兽-{versionName}.apk`

### 17.3 签名

- 签名文件：项目根目录 `kejinshou.jks`
- Debug 包也使用 Release 签名（因支付 SDK 要求）

---

## 18. 交互指南

- **用中文报告结果和沟通**
- 新增代码必须遵循项目现有模式（Butterknife + OkRequest + EventBus + FastJSON2）
- 修改已有页面时，先读取理解现有代码结构再动手
- 涉及支付、推送等核心模块，修改前必须说明影响范围
- 常量统一放在 `constains` 包下对应类中
- 自定义 View 放在 `widget` 包下
- 工具方法优先复用 `utils` 包中已有类，避免重复造轮子
