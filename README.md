# OddsLive

這個專案用 `UIKit + MVVM` 來做即時賠率列表。`OddsPageViewController` 負責列表畫面和狀態顯示，`OddsPageViewModel` 負責把 API、WebSocket 和快取串起來，`OddsCellViewModel` 則只處理單一比賽的顯示資料。初始資料會先把比賽與賠率合併、排序後交給 table view，之後的即時更新只處理已經存在的 cell，不重新建立整份列表。

`Swift Concurrency` 主要用在初始資料載入、平行抓取 matches 和 odds，以及模擬 WebSocket 推播與重連流程。`MatchOddsCacheStore` 用 `actor` 實作，讓快取讀寫集中在同一個隔離區域內，避免多個 task 同時修改資料。`OddsPageViewModel` 和 `MatchWebSocketService` 則放在 `@MainActor` 上，讓畫面相關狀態維持在主執行緒更新。

`Combine` 只用在 cell 這一層。`OddsCellViewModel` 用 `CurrentValueSubject` 保存兩邊隊伍的賠率狀態，`OddsCell` 在綁定 view model 後直接訂閱 publisher。這樣做的原因很單純：賠率更新頻率高，但每次只影響少數幾列，用 publisher 直接推到 cell，比整頁 `reloadData()` 更適合。

UI 和 ViewModel 的綁定分成兩層。頁面層用 closure 處理初始載入、loading、連線狀態和重連倒數；cell 層用 publisher 處理賠率數字的更新。所以實際行為會是：第一次載入時 reload 一次 table，後續收到新賠率時，只更新對應 cell 的 odds 文字和顏色。

目錄底下另附兩個影片檔：

- `demo.MP4`：操作展示影片
- `memoryTest.mov`：藉由 Instruments 觀察 Allocations，確認 memory 是否有正常釋放的測試影片
