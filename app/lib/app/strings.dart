/// Text shown to parents (Traditional Chinese). Children's screens use
/// pictures and voice; these strings are their accessibility labels and the
/// words a character "says".
abstract final class Strings {
  static const appName = '畫畫小鎮';

  // Town map (home).
  static String townOf(String name) => '$name的小鎮';
  static String postcardsSent(int n) => '已經寄了 $n 張明信片';
  static const takePhoto = '拍照畫畫';
  static const album = '明信片冊';
  static const blankPaper = '白紙畫畫';
  static const switchChild = '切換小朋友';
  static const emptyTown = '小鎮還空空的，\n去拍照把它蓋起來吧！';
  static const emptyLot = '去拍照，寄到這裡就會蓋好喔！';
  static const bedtime = '天黑了，小鎮要睡覺囉。\n畫完這張就說晚安吧！';
  static String festivalLetter(String festival) => '$festival到了！\n咕咕送來一張著色畫';
  static String openLetter(String festival) => '打開$festival的信';
  static String pinLabel(String place, int n) => '$place的明信片，$n 張';
  static String postcardsHere(int n) => '$n 張明信片';
  static String latest(String date) => '最近 $date';
  static const drawHere = '在這裡再畫一張';
  static const close = '關閉';

  // Taking or picking a photo.
  static const camera = '用相機拍';
  static const photoLibrary = '從相簿選';
  static const captureHint = '對準你想畫的東西';
  static const backToMap = '回到地圖';

  // Turning the photo into a page.
  static const magic = '變變變！';
  static String magicHint(String name) => '$name正在把照片變成著色畫';
  static const whichOne = '你喜歡哪一張？';
  static const retake = '重拍';
  static const realistic = '真實風格';
  static const cute = '可愛風格';
  static const convertFailed = '這張照片轉不出來，換一張試試看';

  // Coloring.
  static const undo = '復原';
  static const bucket = '油漆桶';
  static const crayon = '魔法蠟筆';
  static const paperColor = '換紙的顏色';
  static const done = '畫好了，寄出';
  static String colorName(String c) => '$c色';

  // Sending.
  static const whereTo = '要寄到哪裡呢？';
  static const lastTime = '上次';
  static const morePlaces = '更多地方';
  static String sendTo(String place) => '寄到$place';
  static const sentStamp = '寄出';
  static const sent = '寄出囉！';
  static String newPlace(String place) => '新地方：$place！';
  static const backToTown = '回到小鎮';
  static const drawAgain = '再畫一張';

  // Album.
  static const all = '全部';
  static const favorites = '最愛';
  static const favorite = '我的最愛';
  static const drafts = '還沒寄出';
  static const emptyAlbum = '還沒有明信片，去拍照畫一張吧！';
  static String count(int n) => '$n 張';

  // Parent gate.
  static const parentGateTitle = '家長確認';
  static const callParent = '請找爸爸或媽媽來喔';
  static String gateQuestion(String a, String b) => '「$a」加「$b」等於多少？';
  static const gateRules = '題目每次都不一樣。答錯 3 次要等 1 分鐘。';
  static String gateWait(int s) => '答錯太多次了，請等 $s 秒';
  static const wrongAnswer = '答案不對，換一題';
  static const backspace = '刪除';

  // Parent mode.
  static const parentMode = '家長模式';
  static const children = '小朋友';
  static const addChild = '新增小朋友';
  static const dailyLimit = '每天可以玩多久';
  static String minutes(int m) => '$m 分';
  static const ourPlaces = '我們的地方';
  static const ourPlacesHint = '不使用定位，小朋友寄出明信片時自己選地方。點一下可以取名字。';
  static const placeName = '幫這個地方取名字';
  static const placeNameHint = '例如：大安森林公園';
  static const save = '儲存';
  static const cancel = '取消';
  static const other = '其他';
  static const privacy = '隱私與安全';
  static const licenses = '開放原始碼授權';
  static String version(String v) => '版本 $v';

  // Privacy page.
  static const allOnPhone = '所有資料都在這支手機';
  static const allOnPhoneBody = '照片、畫、名字都不會離開手機。\n刪掉 APP 就全部刪除。';
  static const noUpload = '不上傳';
  static const noAds = '沒廣告';
  static const noChat = '沒聊天';
  static const noLocation = '不定位';
  static const permissions = 'APP 用到的權限';
  static const permCamera = '相機';
  static const permCameraUse = '按拍照時才用';
  static const permPhotos = '相片';
  static const permPhotosUse = '只讀你選的那張';
  static const permLocation = '位置';
  static const permMicrophone = '麥克風';
  static const permNetwork = '網路';
  static const notUsed = '不使用';
  static const deleteAll = '刪除所有資料';
  static const deleteAllConfirm = '所有作品和小朋友資料都會刪除，而且無法復原。確定要刪除嗎？';
  static const delete = '刪除';
  static const deleted = '已刪除所有資料';
}
