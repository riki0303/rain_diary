<style>
  @import url('https://fonts.googleapis.com/css2?family=Zen+Kaku+Gothic+New:wght@400;500;700&family=Playfair+Display:ital@1&display=swap');
  .rj-root { font-family: 'Zen Kaku Gothic New', sans-serif; color: var(--color-text-primary); }
  .rj-nav { display: flex; align-items: center; justify-content: space-between; padding: 12px 20px; border-bottom: 0.5px solid var(--color-border-tertiary); margin-bottom: 0; }
  .rj-logo { font-size: 15px; font-weight: 700; letter-spacing: 0.04em; }
  .rj-logo span { color: #5DCAA5; }
  .rj-nav-links { display: flex; gap: 16px; align-items: center; }
  .rj-nav-links a { font-size: 12px; color: var(--color-text-secondary); text-decoration: none; }
  .rj-btn { background: #1D9E75; color: #fff; border: none; border-radius: 6px; padding: 6px 14px; font-size: 12px; font-weight: 500; cursor: pointer; font-family: inherit; }
  .rj-btn-sm { background: var(--color-background-secondary); color: var(--color-text-primary); border: 0.5px solid var(--color-border-secondary); border-radius: 6px; padding: 5px 12px; font-size: 12px; cursor: pointer; font-family: inherit; }
  .rj-hero { padding: 24px 20px 16px; border-bottom: 0.5px solid var(--color-border-tertiary); }
  .rj-hero-label { font-size: 11px; color: #1D9E75; font-weight: 500; letter-spacing: 0.08em; margin-bottom: 4px; }
  .rj-hero-title { font-size: 22px; font-weight: 700; margin: 0 0 4px; }
  .rj-hero-sub { font-size: 13px; color: var(--color-text-secondary); }
  .rj-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; padding: 16px 20px; border-bottom: 0.5px solid var(--color-border-tertiary); }
  .rj-stat { background: var(--color-background-secondary); border-radius: 8px; padding: 10px 12px; }
  .rj-stat-num { font-size: 22px; font-weight: 700; color: #1D9E75; }
  .rj-stat-label { font-size: 11px; color: var(--color-text-secondary); margin-top: 2px; }
  .rj-list { padding: 16px 20px; display: flex; flex-direction: column; gap: 10px; }
  .rj-card { background: var(--color-background-primary); border: 0.5px solid var(--color-border-tertiary); border-radius: 12px; padding: 14px 16px; cursor: pointer; transition: border-color 0.15s; }
  .rj-card:hover { border-color: var(--color-border-secondary); }
  .rj-card-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px; }
  .rj-card-date { font-size: 11px; color: var(--color-text-secondary); }
  .rj-card-weather { display: flex; align-items: center; gap: 6px; }
  .rj-badge { font-size: 11px; background: #E1F5EE; color: #0F6E56; border-radius: 4px; padding: 2px 8px; font-weight: 500; }
  .rj-badge-gray { background: var(--color-background-secondary); color: var(--color-text-secondary); }
  .rj-card-title { font-size: 15px; font-weight: 500; margin-bottom: 6px; }
  .rj-card-body { font-size: 13px; color: var(--color-text-secondary); line-height: 1.6; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
  .rj-card-footer { display: flex; align-items: center; gap: 8px; margin-top: 10px; padding-top: 10px; border-top: 0.5px solid var(--color-border-tertiary); }
  .rj-mood { display: flex; gap: 3px; }
  .rj-mood-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--color-border-tertiary); }
  .rj-mood-dot.active { background: #1D9E75; }
  .rj-temp { font-size: 12px; color: var(--color-text-secondary); margin-left: auto; }
  .rj-divider { font-size: 11px; color: var(--color-text-tertiary); padding: 0 20px 8px; }
  .rj-fab { position: absolute; bottom: 16px; right: 16px; background: #1D9E75; color: #fff; border: none; border-radius: 50%; width: 44px; height: 44px; font-size: 22px; cursor: pointer; display: flex; align-items: center; justify-content: center; }
  .rj-wrap { position: relative; }
  .tab-btn { background: none; border: none; padding: 8px 12px; font-size: 13px; font-family: inherit; color: var(--color-text-secondary); cursor: pointer; border-bottom: 2px solid transparent; }
  .tab-btn.active { color: #1D9E75; border-bottom: 2px solid #1D9E75; font-weight: 500; }
  .rj-tabs { display: flex; padding: 0 20px; border-bottom: 0.5px solid var(--color-border-tertiary); }
  .section-label { font-size: 11px; color: var(--color-text-tertiary); letter-spacing: 0.06em; padding: 12px 20px 4px; font-weight: 500; }
</style>

<div class="rj-root rj-wrap">
  <h2 class="sr-only">雨の日ジャーナル — UIモックアップ（一覧画面）</h2>

  <div class="rj-nav">
    <div class="rj-logo">🌧 Rainy<span>Journal</span></div>
    <div class="rj-nav-links">
      <a href="#">思い出</a>
      <a href="#">統計</a>
      <button class="rj-btn" onclick="sendPrompt('新規作成フォームのビューコードを見せて')">+ 記録する</button>
    </div>
  </div>

  <div class="rj-hero">
    <div class="rj-hero-label">TODAY — 2025.04.20 東京</div>
    <div class="rj-hero-title">今日も雨ですね ☁️</div>
    <div class="rj-hero-sub">気温 14.5℃ · 湿度 82% · 小雨 3.2mm</div>
  </div>

  <div class="rj-stats">
    <div class="rj-stat">
      <div class="rj-stat-num">24</div>
      <div class="rj-stat-label">雨の日の記録</div>
    </div>
    <div class="rj-stat">
      <div class="rj-stat-num">12</div>
      <div class="rj-stat-label">今年の記録</div>
    </div>
    <div class="rj-stat">
      <div class="rj-stat-num">4.2</div>
      <div class="rj-stat-label">平均気分</div>
    </div>
  </div>

  <div class="rj-tabs">
    <button class="tab-btn active">すべて</button>
    <button class="tab-btn">今年</button>
    <button class="tab-btn">気分よかった日</button>
  </div>

  <div class="rj-list">
    <div class="section-label">最近の記録</div>

    <div class="rj-card" onclick="sendPrompt('詳細ページ（show）のビューコードを見せて')">
      <div class="rj-card-top">
        <div class="rj-card-date">2025年4月20日 日曜日</div>
        <div class="rj-card-weather">
          <span class="rj-badge">小雨</span>
          <span class="rj-badge rj-badge-gray">14.5℃</span>
        </div>
      </div>
      <div class="rj-card-title">雨の日に映画を見た</div>
      <div class="rj-card-body">家でずっとNetflix見てた。外の雨音が気持ちよくて、久しぶりにゆっくりできた気がする。</div>
      <div class="rj-card-footer">
        <div class="rj-mood">
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot"></div>
        </div>
        <span class="rj-temp">気分 4 / 5</span>
      </div>
    </div>

    <div class="rj-card">
      <div class="rj-card-top">
        <div class="rj-card-date">2025年4月12日 土曜日</div>
        <div class="rj-card-weather">
          <span class="rj-badge">大雨</span>
          <span class="rj-badge rj-badge-gray">11.2℃</span>
        </div>
      </div>
      <div class="rj-card-title">雨の中、図書館へ</div>
      <div class="rj-card-body">傘をさして近所の図書館まで歩いた。びしょびしょになったけど、なんか清々しかった。</div>
      <div class="rj-card-footer">
        <div class="rj-mood">
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
        </div>
        <span class="rj-temp">気分 5 / 5</span>
      </div>
    </div>

    <div class="rj-card">
      <div class="rj-card-top">
        <div class="rj-card-date">2025年3月28日 金曜日</div>
        <div class="rj-card-weather">
          <span class="rj-badge">霧雨</span>
          <span class="rj-badge rj-badge-gray">9.8℃</span>
        </div>
      </div>
      <div class="rj-card-title">コーヒーと読書の午後</div>
      <div class="rj-card-body">窓の外の雨を眺めながらコーヒーを飲んだ。買ったまま積んでた本をやっと読み始めた。</div>
      <div class="rj-card-footer">
        <div class="rj-mood">
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot active"></div>
          <div class="rj-mood-dot"></div>
          <div class="rj-mood-dot"></div>
        </div>
        <span class="rj-temp">気分 3 / 5</span>
      </div>
    </div>
  </div>

<button class="rj-fab" onclick="sendPrompt('新規作成フォームのビューコードを見せて')">+</button>
</div>
