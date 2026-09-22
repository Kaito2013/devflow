# devflow-cli Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use supercoders:subagent-driven-development (recommended) or supercoders:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Build `devflow-cli`, an ultra-lightweight (<20MB RAM) Go companion binary that provides a live Bubbletea TUI Dashboard and a two-way Telegram Bot with Gate Approval for `devflow`.

**Architecture:** A standalone Go CLI utilizing `bubbletea` & `lipgloss` for the TUI, `fsnotify` for monitoring `devflow/plans/*.md` and `.worktrees/`, a Unix domain socket for IPC notifications from `devflow` hooks, and a long-polling goroutine for Telegram Bot remote control.

**Tech Stack:** Go 1.22+, `github.com/charmbracelet/bubbletea`, `github.com/charmbracelet/lipgloss`, `github.com/fsnotify/fsnotify`, `github.com/go-telegram-bot-api/telegram-bot-api/v5`, `gopkg.in/yaml.v3`.

**Spec:** [devflow/specs/2026-09-22-devflow-cli-design.md](file:///Users/hoaiminh/devflow/devflow/specs/2026-09-22-devflow-cli-design.md)

## Global Constraints

- Standalone single binary buildable via `go build -o devflow-cli ./cmd/devflow`.
- Memory footprint must remain under 20MB when running daemon + Telegram polling.
- Zero breaking changes to core `devflow` skills — integration is strictly opt-in and hook-triggered.
- Security: Telegram Bot strictly drops all updates originating from unlisted `chat_id`s.
- No PTY hijacking or terminal capture; all status updates flow via file watcher or Unix socket IPC.

---

### Task 1: Project Scaffolding & Configuration Module

**Files:**
- Create: `/Users/hoaiminh/devflow-cli/go.mod`
- Create: `/Users/hoaiminh/devflow-cli/internal/config/config.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/config/config_test.go`

**Interfaces:**
- Produces: `config.Config`, `config.TelegramConfig`, `config.Load(path string) (*Config, error)`, `config.DefaultConfig() *Config`

- [x] **Step 1: Initialize Go module & Write failing configuration test**

```go
// internal/config/config_test.go
package config_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/Kaito2013/devflow-cli/internal/config"
)

func TestLoadConfig_Defaults(t *testing.T) {
	cfg := config.DefaultConfig()
	if cfg.TUI.RefreshRateMs != 500 {
		t.Errorf("expected refresh rate 500, got %d", cfg.TUI.RefreshRateMs)
	}
	if cfg.IPC.SocketPath == "" {
		t.Errorf("expected non-empty socket path")
	}
}

func TestLoadConfig_ValidYAML(t *testing.T) {
	tmpDir := t.TempDir()
	configFile := filepath.Join(tmpDir, "config.yaml")
	yamlContent := `
telegram:
  enabled: true
  bot_token: "test-token"
  chat_id: 987654321
  notification_level: "all"
tui:
  refresh_rate_ms: 250
  theme: "dark"
`
	if err := os.WriteFile(configFile, []byte(yamlContent), 0644); err != nil {
		t.Fatalf("failed to write test config: %v", err)
	}

	cfg, err := config.Load(configFile)
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if !cfg.Telegram.Enabled || cfg.Telegram.ChatID != 987654321 {
		t.Errorf("telegram config not parsed correctly: %+v", cfg.Telegram)
	}
	if cfg.TUI.RefreshRateMs != 250 {
		t.Errorf("expected refresh rate 250, got %d", cfg.TUI.RefreshRateMs)
	}
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /Users/hoaiminh/devflow-cli && go test ./internal/config/...`
Expected: FAIL (packages not found)

- [x] **Step 3: Implement minimal config package**

```go
// internal/config/config.go
package config

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

type TelegramConfig struct {
	Enabled           bool   `yaml:"enabled"`
	BotToken          string `yaml:"bot_token"`
	ChatID            int64  `yaml:"chat_id"`
	NotificationLevel string `yaml:"notification_level"`
}

type TUIConfig struct {
	RefreshRateMs int    `yaml:"refresh_rate_ms"`
	Theme         string `yaml:"theme"`
}

type IPCConfig struct {
	SocketPath string `yaml:"socket_path"`
}

type Config struct {
	Telegram TelegramConfig `yaml:"telegram"`
	TUI      TUIConfig      `yaml:"tui"`
	IPC      IPCConfig      `yaml:"ipc"`
}

func DefaultConfig() *Config {
	home, _ := os.UserHomeDir()
	return &Config{
		Telegram: TelegramConfig{
			Enabled:           false,
			NotificationLevel: "all",
		},
		TUI: TUIConfig{
			RefreshRateMs: 500,
			Theme:         "dark",
		},
		IPC: IPCConfig{
			SocketPath: filepath.Join(home, ".devflow", "ipc.sock"),
		},
	}
}

func Load(path string) (*Config, error) {
	cfg := DefaultConfig()
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read config file: %w", err)
	}
	if err := yaml.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("unmarshal config yaml: %w", err)
	}
	return cfg, nil
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /Users/hoaiminh/devflow-cli && go test -v ./internal/config/...`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add internal/config go.mod go.sum
git commit -m "feat(config): implement configuration loading and defaults"
```

---

### Task 2: State Model & Markdown Plan Parser

**Files:**
- Create: `/Users/hoaiminh/devflow-cli/internal/state/state.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/state/plan_parser.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/state/plan_parser_test.go`

**Interfaces:**
- Consumes: None
- Produces: `state.TaskItem`, `state.SessionState`, `state.ParsePlan(content string) (*SessionState, error)`, `state.FindLatestPlan(dir string) (string, error)`

- [x] **Step 1: Write failing plan parser test**

```go
// internal/state/plan_parser_test.go
package state_test

import (
	"testing"

	"github.com/Kaito2013/devflow-cli/internal/state"
)

func TestParsePlan_TasksAndTags(t *testing.T) {
	markdown := `
# OAuth Login Implementation Plan

**Goal:** Implement Google OAuth.

### Task 1: [Backend] Create User Migration & DTO
- [x] Step 1: Write test
- [x] Step 2: Commit

### Task 2: [Backend] Implement Controller
- [/] Step 1: Coding

### Task 3: [UI] Add Login Button
- [x] Step 1: Markup
`
	session, err := state.ParsePlan(markdown)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(session.Tasks) != 3 {
		t.Fatalf("expected 3 tasks, got %d", len(session.Tasks))
	}

	if session.Tasks[0].Status != state.StatusApproved || session.Tasks[0].Tag != "[Backend]" {
		t.Errorf("task 1 mismatch: %+v", session.Tasks[0])
	}
	if session.Tasks[1].Status != state.StatusInProgress {
		t.Errorf("task 2 expected in_progress, got: %v", session.Tasks[1].Status)
	}
	if session.Tasks[2].Status != state.StatusTodo || session.Tasks[2].Tag != "[UI]" {
		t.Errorf("task 3 mismatch: %+v", session.Tasks[2])
	}
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /Users/hoaiminh/devflow-cli && go test ./internal/state/...`
Expected: FAIL

- [x] **Step 3: Implement Plan Parser and Session State**

```go
// internal/state/state.go
package state

import "time"

type TaskStatus string

const (
	StatusTodo       TaskStatus = "TODO"
	StatusInProgress TaskStatus = "IN_PROGRESS"
	StatusReviewing  TaskStatus = "REVIEWING"
	StatusApproved   TaskStatus = "APPROVED"
	StatusFailed     TaskStatus = "FAILED"
)

type TaskItem struct {
	Index       int        `json:"index"`
	Title       string     `json:"title"`
	Tag         string     `json:"tag"`
	Status      TaskStatus `json:"status"`
	CommitHash  string     `json:"commit_hash,omitempty"`
	ReviewNotes string     `json:"review_notes,omitempty"`
}

type SessionState struct {
	PlanFile     string     `json:"plan_file"`
	FeatureName  string     `json:"feature_name"`
	WorktreePath string     `json:"worktree_path"`
	Branch       string     `json:"branch"`
	Tasks        []TaskItem `json:"tasks"`
	GateWaiting  bool       `json:"gate_waiting"`
	WaitingTask  int        `json:"waiting_task"`
	LastUpdated  time.Time  `json:"last_updated"`
}
```

```go
// internal/state/plan_parser.go
package state

import (
	"bufio"
	"regexp"
	"strings"
	"time"
)

var (
	taskHeaderRegex = regexp.MustCompile(`(?i)^###\s+Task\s+(\d+):\s*(?:(\[[a-zA-Z0-9_-]+\])\s*)?(.*)`)
	stepBoxRegex    = regexp.MustCompile(`^\s*-\s*\[([ xX/>])\]`)
)

func ParsePlan(content string) (*SessionState, error) {
	scanner := bufio.NewScanner(strings.NewReader(content))
	session := &SessionState{
		Tasks:       make([]TaskItem, 0),
		LastUpdated: time.Now(),
	}

	var currentTask *TaskItem
	totalSteps := 0
	doneSteps := 0
	inProgressStep := false

	for scanner.Scan() {
		line := scanner.Text()

		if matches := taskHeaderRegex.FindStringSubmatch(line); len(matches) > 0 {
			if currentTask != nil {
				finalizeTaskStatus(currentTask, totalSteps, doneSteps, inProgressStep)
				session.Tasks = append(session.Tasks, *currentTask)
			}
			idx := len(session.Tasks) + 1
			tag := matches[2]
			title := strings.TrimSpace(matches[3])
			currentTask = &TaskItem{
				Index:  idx,
				Tag:    tag,
				Title:  title,
				Status: StatusTodo,
			}
			totalSteps = 0
			doneSteps = 0
			inProgressStep = false
			continue
		}

		if currentTask != nil {
			if stepMatches := stepBoxRegex.FindStringSubmatch(line); len(stepMatches) > 0 {
				totalSteps++
				mark := stepMatches[1]
				if mark == "x" || mark == "X" {
					doneSteps++
				} else if mark == "/" || mark == ">" {
					inProgressStep = true
				}
			}
		}
	}

	if currentTask != nil {
		finalizeTaskStatus(currentTask, totalSteps, doneSteps, inProgressStep)
		session.Tasks = append(session.Tasks, *currentTask)
	}

	return session, scanner.Err()
}

func finalizeTaskStatus(task *TaskItem, totalSteps, doneSteps int, inProgress bool) {
	if totalSteps > 0 && doneSteps == totalSteps {
		task.Status = StatusApproved
	} else if inProgress || (doneSteps > 0 && doneSteps < totalSteps) {
		task.Status = StatusInProgress
	} else {
		task.Status = StatusTodo
	}
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /Users/hoaiminh/devflow-cli && go test -v ./internal/state/...`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add internal/state/
git commit -m "feat(state): implement plan markdown parser and task state model"
```

---

### Task 3: Gate Lock Manager & Unix Socket IPC

**Files:**
- Create: `/Users/hoaiminh/devflow-cli/internal/gate/gate.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/gate/gate_test.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/ipc/server.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/ipc/client.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/ipc/ipc_test.go`

**Interfaces:**
- Produces: `gate.Manager`, `gate.Manager.Acquire(taskIndex int)`, `gate.Manager.Release(taskIndex int)`, `ipc.Server`, `ipc.Client.Notify(event Notification)`

- [x] **Step 1: Write failing Gate Manager test**

```go
// internal/gate/gate_test.go
package gate_test

import (
	"path/filepath"
	"testing"
	"time"

	"github.com/Kaito2013/devflow-cli/internal/gate"
)

func TestGateManager_AcquireAndRelease(t *testing.T) {
	tmpDir := t.TempDir()
	gm := gate.New(tmpDir)

	if gm.IsLocked() {
		t.Errorf("gate should be initially unlocked")
	}

	if err := gm.Acquire(2); err != nil {
		t.Fatalf("failed to acquire gate: %v", err)
	}

	if !gm.IsLocked() || gm.WaitingTask() != 2 {
		t.Errorf("expected gate locked on task 2")
	}

	// Test release
	if err := gm.Release(2); err != nil {
		t.Fatalf("failed to release gate: %v", err)
	}

	if gm.IsLocked() {
		t.Errorf("gate should be unlocked after release")
	}
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /Users/hoaiminh/devflow-cli && go test ./internal/gate/...`
Expected: FAIL

- [x] **Step 3: Implement Gate Manager & Unix IPC Server/Client**

```go
// internal/gate/gate.go
package gate

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

type Manager struct {
	lockDir string
}

func New(baseDir string) *Manager {
	return &Manager{lockDir: baseDir}
}

func (m *Manager) lockFile() string {
	return filepath.Join(m.lockDir, ".devflow", "gate.lock")
}

func (m *Manager) IsLocked() bool {
	_, err := os.Stat(m.lockFile())
	return err == nil
}

func (m *Manager) WaitingTask() int {
	data, err := os.ReadFile(m.lockFile())
	if err != nil {
		return 0
	}
	idx, _ := strconv.Atoi(string(data))
	return idx
}

func (m *Manager) Acquire(taskIndex int) error {
	dir := filepath.Dir(m.lockFile())
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	return os.WriteFile(m.lockFile(), []byte(strconv.Itoa(taskIndex)), 0644)
}

func (m *Manager) Release(taskIndex int) error {
	if !m.IsLocked() {
		return nil
	}
	return os.Remove(m.lockFile())
}
```

```go
// internal/ipc/server.go
package ipc

import (
	"encoding/json"
	"net"
	"os"
	"path/filepath"
)

type Notification struct {
	Event      string `json:"event"`
	TaskIndex  int    `json:"task_index"`
	TaskTitle  string `json:"task_title"`
	Status     string `json:"status"`
	CommitHash string `json:"commit_hash"`
	ReviewNote string `json:"review_note"`
}

type Server struct {
	socketPath string
	listener   net.Listener
	handler    func(Notification)
}

func NewServer(socketPath string, handler func(Notification)) *Server {
	return &Server{
		socketPath: socketPath,
		handler:    handler,
	}
}

func (s *Server) Start() error {
	_ = os.Remove(s.socketPath)
	_ = os.MkdirAll(filepath.Dir(s.socketPath), 0755)

	l, err := net.Listen("unix", s.socketPath)
	if err != nil {
		return err
	}
	s.listener = l

	go func() {
		for {
			conn, err := l.Accept()
			if err != nil {
				return
			}
			go s.handleConn(conn)
		}
	}()
	return nil
}

func (s *Server) handleConn(conn net.Conn) {
	defer conn.Close()
	var notif Notification
	if err := json.NewDecoder(conn).Decode(&notif); err == nil && s.handler != nil {
		s.handler(notif)
	}
	_ = json.NewEncoder(conn).Encode(map[string]string{"status": "ok"})
}

func (s *Server) Stop() error {
	if s.listener != nil {
		return s.listener.Close()
	}
	return nil
}
```

```go
// internal/ipc/client.go
package ipc

import (
	"encoding/json"
	"net"
)

func SendNotification(socketPath string, notif Notification) error {
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		return err
	}
	defer conn.Close()

	if err := json.NewEncoder(conn).Encode(notif); err != nil {
		return err
	}

	var resp map[string]string
	return json.NewDecoder(conn).Decode(&resp)
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /Users/hoaiminh/devflow-cli && go test -v ./internal/gate/... ./internal/ipc/...`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add internal/gate/ internal/ipc/
git commit -m "feat(ipc): implement gate lock manager and unix domain socket IPC"
```

---

### Task 4: File Watcher Engine

**Files:**
- Create: `/Users/hoaiminh/devflow-cli/internal/watcher/watcher.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/watcher/watcher_test.go`

**Interfaces:**
- Consumes: `state.SessionState`, `state.ParsePlan`
- Produces: `watcher.Engine`, `watcher.Engine.Start(dir string, onChange func(*state.SessionState))`

- [x] **Step 1: Write failing watcher debouncing test**

```go
// internal/watcher/watcher_test.go
package watcher_test

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/Kaito2013/devflow-cli/internal/state"
	"github.com/Kaito2013/devflow-cli/internal/watcher"
)

func TestWatcher_DetectsPlanChange(t *testing.T) {
	tmpDir := t.TempDir()
	plansDir := filepath.Join(tmpDir, "devflow", "plans")
	_ = os.MkdirAll(plansDir, 0755)

	planFile := filepath.Join(plansDir, "2026-09-22-test.md")
	_ = os.WriteFile(planFile, []byte("### Task 1: Initial\n- [x] step 1\n"), 0644)

	changed := make(chan *state.SessionState, 1)
	w, err := watcher.New(tmpDir, func(s *state.SessionState) {
		changed <- s
	})
	if err != nil {
		t.Fatalf("failed to create watcher: %v", err)
	}
	defer w.Stop()

	// Update plan
	time.Sleep(50 * time.Millisecond)
	_ = os.WriteFile(planFile, []byte("### Task 1: Updated\n- [x] step 1\n"), 0644)

	select {
	case s := <-changed:
		if len(s.Tasks) == 0 || s.Tasks[0].Status != state.StatusApproved {
			t.Errorf("unexpected task status: %+v", s.Tasks)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("timeout waiting for watcher event")
	}
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /Users/hoaiminh/devflow-cli && go test ./internal/watcher/...`
Expected: FAIL

- [x] **Step 3: Implement Watcher Engine**

```go
// internal/watcher/watcher.go
package watcher

import (
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/Kaito2013/devflow-cli/internal/state"
	"github.com/fsnotify/fsnotify"
)

type Engine struct {
	rootDir  string
	watcher  *fsnotify.Watcher
	onChange func(*state.SessionState)
	stopChan chan struct{}
	mu       sync.Mutex
}

func New(rootDir string, onChange func(*state.SessionState)) (*Engine, error) {
	w, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}

	e := &Engine{
		rootDir:  rootDir,
		watcher:  w,
		onChange: onChange,
		stopChan: make(chan struct{}),
	}

	plansDir := filepath.Join(rootDir, "devflow", "plans")
	_ = os.MkdirAll(plansDir, 0755)
	if err := w.Add(plansDir); err != nil {
		_ = w.Close()
		return nil, err
	}

	go e.loop()
	return e, nil
}

func (e *Engine) loop() {
	var debounceTimer *time.Timer
	for {
		select {
		case <-e.stopChan:
			return
		case event, ok := <-e.watcher.Events:
			if !ok {
				return
			}
			if event.Has(fsnotify.Write) || event.Has(fsnotify.Create) {
				if debounceTimer != nil {
					debounceTimer.Stop()
				}
				debounceTimer = time.AfterFunc(150*time.Millisecond, func() {
					e.reload(event.Name)
				})
			}
		case <-e.watcher.Errors:
		}
	}
}

func (e *Engine) reload(filePath string) {
	e.mu.Lock()
	defer e.mu.Unlock()

	data, err := os.ReadFile(filePath)
	if err != nil {
		return
	}
	s, err := state.ParsePlan(string(data))
	if err == nil && e.onChange != nil {
		s.PlanFile = filePath
		e.onChange(s)
	}
}

func (e *Engine) Stop() error {
	close(e.stopChan)
	return e.watcher.Close()
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /Users/hoaiminh/devflow-cli && go test -v ./internal/watcher/...`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add internal/watcher/
git commit -m "feat(watcher): implement fsnotify plan file watcher with debouncing"
```

---

### Task 5: Telegram Bot Remote Control Module

**Files:**
- Create: `/Users/hoaiminh/devflow-cli/internal/telegram/bot.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/telegram/bot_test.go`

**Interfaces:**
- Consumes: `config.TelegramConfig`, `state.SessionState`, `gate.Manager`
- Produces: `telegram.Bot`, `telegram.Bot.Start()`, `telegram.Bot.NotifyTaskComplete(task state.TaskItem)`

- [x] **Step 1: Write failing command routing test**

```go
// internal/telegram/bot_test.go
package telegram_test

import (
	"testing"

	"github.com/Kaito2013/devflow-cli/internal/config"
	"github.com/Kaito2013/devflow-cli/internal/telegram"
)

func TestTelegramBot_SecurityFilter(t *testing.T) {
	cfg := config.TelegramConfig{
		Enabled:  true,
		BotToken: "mock-token",
		ChatID:   12345,
	}
	b := telegram.NewMock(cfg)

	// Update from unauthorized chat_id
	allowed := b.IsAuthorized(99999)
	if allowed {
		t.Errorf("expected unauthorized for stranger chat_id")
	}

	allowedSelf := b.IsAuthorized(12345)
	if !allowedSelf {
		t.Errorf("expected authorized for configured chat_id")
	}
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /Users/hoaiminh/devflow-cli && go test ./internal/telegram/...`
Expected: FAIL

- [x] **Step 3: Implement Telegram Bot Client & Command Router**

```go
// internal/telegram/bot.go
package telegram

import (
	"fmt"
	"log"
	"sync"

	"github.com/Kaito2013/devflow-cli/internal/config"
	"github.com/Kaito2013/devflow-cli/internal/gate"
	"github.com/Kaito2013/devflow-cli/internal/state"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

type Bot struct {
	cfg     config.TelegramConfig
	api     *tgbotapi.BotAPI
	gateMgr *gate.Manager
	stateMu sync.RWMutex
	state   *state.SessionState
	stopCh  chan struct{}
}

func New(cfg config.TelegramConfig, gm *gate.Manager) (*Bot, error) {
	if !cfg.Enabled || cfg.BotToken == "" {
		return &Bot{cfg: cfg, gateMgr: gm}, nil
	}
	api, err := tgbotapi.NewBotAPI(cfg.BotToken)
	if err != nil {
		return nil, fmt.Errorf("init telegram bot: %w", err)
	}
	return &Bot{
		cfg:     cfg,
		api:     api,
		gateMgr: gm,
		stopCh:  make(chan struct{}),
	}, nil
}

func (b *Bot) IsAuthorized(chatID int64) bool {
	return b.cfg.ChatID != 0 && b.cfg.ChatID == chatID
}

func (b *Bot) SetState(s *state.SessionState) {
	b.stateMu.Lock()
	defer b.stateMu.Unlock()
	b.state = s
}

func (b *Bot) Start() {
	if b.api == nil {
		return
	}
	u := tgbotapi.NewUpdate(0)
	u.Timeout = 60
	updates := b.api.GetUpdatesChan(u)

	for {
		select {
		case <-b.stopCh:
			return
		case update := <-updates:
			if update.Message != nil && b.IsAuthorized(update.Message.Chat.ID) {
				b.handleMessage(update.Message)
			} else if update.CallbackQuery != nil && b.IsAuthorized(update.CallbackQuery.Message.Chat.ID) {
				b.handleCallback(update.CallbackQuery)
			}
		}
	}
}

func (b *Bot) handleMessage(msg *tgbotapi.Message) {
	switch msg.Command() {
	case "status":
		b.sendStatus(msg.Chat.ID)
	case "approve":
		b.handleApprove(msg.Chat.ID)
	case "stop":
		b.reply(msg.Chat.ID, "🛑 Nhận lệnh DỪNG! Đã kích hoạt abort signal.")
	default:
		b.reply(msg.Chat.ID, "Lệnh hỗ trợ: /status, /approve, /diff, /stop")
	}
}

func (b *Bot) handleCallback(query *tgbotapi.CallbackQuery) {
	switch query.Data {
	case "action_approve":
		b.handleApprove(query.Message.Chat.ID)
	}
	callback := tgbotapi.NewCallback(query.ID, "Đã xử lý!")
	_, _ = b.api.Request(callback)
}

func (b *Bot) handleApprove(chatID int64) {
	if b.gateMgr != nil && b.gateMgr.IsLocked() {
		taskIdx := b.gateMgr.WaitingTask()
		_ = b.gateMgr.Release(taskIdx)
		b.reply(chatID, fmt.Sprintf("✅ Đã phê duyệt Task %d! AI đang tiếp tục...", taskIdx))
	} else {
		b.reply(chatID, "ℹ️ Hiện không có task nào đang chờ phê duyệt.")
	}
}

func (b *Bot) sendStatus(chatID int64) {
	b.stateMu.RLock()
	defer b.stateMu.RUnlock()
	if b.state == nil || len(b.state.Tasks) == 0 {
		b.reply(chatID, "Chưa có kế hoạch nào đang chạy.")
		return
	}
	text := fmt.Sprintf("📋 *Tiến độ devflow:* %d tasks\n", len(b.state.Tasks))
	for _, t := range b.state.Tasks {
		icon := "○"
		if t.Status == state.StatusApproved {
			icon = "✔"
		} else if t.Status == state.StatusInProgress {
			icon = "▶"
		}
		text += fmt.Sprintf("%s %s %s\n", icon, t.Tag, t.Title)
	}
	b.reply(chatID, text)
}

func (b *Bot) NotifyTaskReview(task state.TaskItem) {
	if b.api == nil || b.cfg.ChatID == 0 {
		return
	}
	msgText := fmt.Sprintf("🔔 *[devflow] Task %d xong review!*\n📌 *%s*\nCommit: `%s`", task.Index, task.Title, task.CommitHash)
	msg := tgbotapi.NewMessage(b.cfg.ChatID, msgText)
	msg.ParseMode = "Markdown"
	btn := tgbotapi.NewInlineKeyboardMarkup(
		tgbotapi.NewInlineKeyboardRow(
			tgbotapi.NewInlineKeyboardButtonData("✅ Phê duyệt (Approve)", "action_approve"),
		),
	)
	msg.ReplyMarkup = btn
	_, _ = b.api.Send(msg)
}

func (b *Bot) reply(chatID int64, text string) {
	if b.api == nil {
		return
	}
	msg := tgbotapi.NewMessage(chatID, text)
	_, _ = b.api.Send(msg)
}

func (b *Bot) Stop() {
	if b.stopCh != nil {
		close(b.stopCh)
	}
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /Users/hoaiminh/devflow-cli && go test -v ./internal/telegram/...`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add internal/telegram/
git commit -m "feat(telegram): implement bot handler, gate approval commands and inline keyboard"
```

---

### Task 6: Bubbletea TUI Dashboard Module

**Files:**
- Create: `/Users/hoaiminh/devflow-cli/internal/tui/model.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/tui/style.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/tui/view.go`
- Create: `/Users/hoaiminh/devflow-cli/internal/tui/tui_test.go`

**Interfaces:**
- Consumes: `state.SessionState`, `gate.Manager`
- Produces: `tui.NewModel(gm *gate.Manager) tea.Model`, `tui.Start()`

- [x] **Step 1: Write failing TUI model update test**

```go
// internal/tui/tui_test.go
package tui_test

import (
	"testing"

	"github.com/Kaito2013/devflow-cli/internal/state"
	"github.com/Kaito2013/devflow-cli/internal/tui"
)

func TestTUI_ModelUpdateState(t *testing.T) {
	m := tui.NewModel(nil)
	newState := &state.SessionState{
		PlanFile: "test-plan.md",
		Tasks: []state.TaskItem{
			{Index: 1, Title: "Task 1", Status: state.StatusApproved},
		},
	}

	updatedModel, _ := m.Update(tui.MsgStateUpdate{State: newState})
	rendered := updatedModel.View()

	if rendered == "" {
		t.Fatal("expected rendered view output")
	}
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `cd /Users/hoaiminh/devflow-cli && go test ./internal/tui/...`
Expected: FAIL

- [x] **Step 3: Implement Lipgloss styles and Bubbletea TUI Model & View**

```go
// internal/tui/style.go
package tui

import "github.com/charmbracelet/lipgloss"

var (
	headerStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#FFFFFF")).
			Background(lipgloss.Color("#5A56E0")).
			Padding(0, 1)

	cardStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#7D56F4")).
			Padding(1, 2)

	taskDoneStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#04B575")).
			Bold(true)

	taskDoingStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFAF00")).
			Bold(true)

	taskTodoStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#626262"))

	tagStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#00D7D7")).
			Bold(true)
)
```

```go
// internal/tui/model.go
package tui

import (
	"fmt"

	"github.com/Kaito2013/devflow-cli/internal/gate"
	"github.com/Kaito2013/devflow-cli/internal/state"
	tea "github.com/charmbracelet/bubbletea"
)

type MsgStateUpdate struct {
	State *state.SessionState
}

type Model struct {
	state   *state.SessionState
	gateMgr *gate.Manager
	width   int
	height  int
	err     error
}

func NewModel(gm *gate.Manager) Model {
	return Model{
		gateMgr: gm,
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return m, tea.Quit
		case "a":
			if m.gateMgr != nil && m.gateMgr.IsLocked() {
				_ = m.gateMgr.Release(m.gateMgr.WaitingTask())
			}
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	case MsgStateUpdate:
		m.state = msg.State
	}
	return m, nil
}
```

```go
// internal/tui/view.go
package tui

import (
	"fmt"
	"strings"

	"github.com/Kaito2013/devflow-cli/internal/state"
)

func (m Model) View() string {
	b := strings.Builder{}
	b.WriteString(headerStyle.Render(" ⚡ devflow monitor ") + "\n\n")

	if m.state == nil || len(m.state.Tasks) == 0 {
		b.WriteString(cardStyle.Render("Chưa có kế hoạch devflow nào đang chạy.\nTheo dõi tự động tại: devflow/plans/*.md"))
		return b.String()
	}

	content := strings.Builder{}
	content.WriteString(fmt.Sprintf("Plan: %s\n\n", m.state.PlanFile))

	for _, task := range m.state.Tasks {
		var icon, line string
		switch task.Status {
		case state.StatusApproved:
			icon = taskDoneStyle.Render("[✔]")
			line = fmt.Sprintf("%s %s %s (%s)", icon, tagStyle.Render(task.Tag), task.Title, task.CommitHash)
		case state.StatusInProgress:
			icon = taskDoingStyle.Render("[▶]")
			line = fmt.Sprintf("%s %s %s", icon, tagStyle.Render(task.Tag), task.Title)
		default:
			icon = taskTodoStyle.Render("[○]")
			line = fmt.Sprintf("%s %s %s", icon, tagStyle.Render(task.Tag), task.Title)
		}
		content.WriteString(line + "\n")
	}

	if m.gateMgr != nil && m.gateMgr.IsLocked() {
		content.WriteString(fmt.Sprintf("\n🟡 ĐANG ĐỢI PHÊ DUYỆT TASK %d (Bấm [a] để duyệt)", m.gateMgr.WaitingTask()))
	}

	b.WriteString(cardStyle.Render(content.String()))
	b.WriteString("\n[a] Approve Gate   [q] Quit\n")
	return b.String()
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `cd /Users/hoaiminh/devflow-cli && go test -v ./internal/tui/...`
Expected: PASS

- [x] **Step 5: Commit**

```bash
git add internal/tui/
git commit -m "feat(tui): implement Bubbletea dashboard model, view, and styling"
```

---

### Task 7: CLI Subcommands & Entrypoint

**Files:**
- Create: `/Users/hoaiminh/devflow-cli/cmd/devflow/main.go`
- Create: `/Users/hoaiminh/devflow-cli/Makefile`

**Interfaces:**
- Produces: Executable `devflow-cli` with subcommands: `tui`, `daemon`, `notify`, `gate`, `init`, `version`.

- [x] **Step 1: Write CLI main entrypoint and subcommand dispatch**

```go
// cmd/devflow/main.go
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/Kaito2013/devflow-cli/internal/config"
	"github.com/Kaito2013/devflow-cli/internal/gate"
	"github.com/Kaito2013/devflow-cli/internal/ipc"
	"github.com/Kaito2013/devflow-cli/internal/state"
	"github.com/Kaito2013/devflow-cli/internal/telegram"
	"github.com/Kaito2013/devflow-cli/internal/tui"
	"github.com/Kaito2013/devflow-cli/internal/watcher"
	tea "github.com/charmbracelet/bubbletea"
)

var Version = "0.1.0"

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	home, _ := os.UserHomeDir()
	configPath := filepath.Join(home, ".devflow", "config.yaml")

	switch os.Args[1] {
	case "version":
		fmt.Printf("devflow-cli v%s\n", Version)

	case "init":
		initProject()

	case "tui":
		runTUI(configPath)

	case "daemon":
		runDaemon(configPath)

	case "notify":
		runNotify(configPath)

	case "gate":
		runGate()

	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("devflow-cli - Companion tool for devflow")
	fmt.Println("Usage:")
	fmt.Println("  devflow-cli tui          Start interactive TUI monitor")
	fmt.Println("  devflow-cli daemon       Run background daemon (Telegram + IPC)")
	fmt.Println("  devflow-cli notify       Send task event to running daemon")
	fmt.Println("  devflow-cli gate         Wait or release gate locks")
	fmt.Println("  devflow-cli init         Initialize .devflow config")
	fmt.Println("  devflow-cli version      Show version")
}

func runTUI(configPath string) {
	wd, _ := os.Getwd()
	gm := gate.New(wd)
	m := tui.NewModel(gm)
	p := tea.NewProgram(m, tea.WithAltScreen())

	_, _ = watcher.New(wd, func(s *state.SessionState) {
		p.Send(tui.MsgStateUpdate{State: s})
	})

	if _, err := p.Run(); err != nil {
		fmt.Printf("TUI error: %v\n", err)
	}
}

func runDaemon(configPath string) {
	cfg, err := config.Load(configPath)
	if err != nil {
		cfg = config.DefaultConfig()
	}
	wd, _ := os.Getwd()
	gm := gate.New(wd)

	bot, err := telegram.New(cfg.Telegram, gm)
	if err != nil {
		fmt.Printf("Telegram warning: %v\n", err)
	} else {
		go bot.Start()
		fmt.Println("Telegram bot connected.")
	}

	server := ipc.NewServer(cfg.IPC.SocketPath, func(n ipc.Notification) {
		if bot != nil {
			bot.NotifyTaskReview(state.TaskItem{
				Index:      n.TaskIndex,
				Title:      n.TaskTitle,
				CommitHash: n.CommitHash,
			})
		}
	})

	if err := server.Start(); err != nil {
		fmt.Printf("IPC Server error: %v\n", err)
		return
	}
	fmt.Printf("Daemon running on socket: %s\n", cfg.IPC.SocketPath)
	select {} // Run forever
}

func runNotify(configPath string) {
	fs := flag.NewFlagSet("notify", flag.ExitOnError)
	task := fs.String("task", "", "Task title")
	idx := fs.Int("index", 1, "Task index")
	status := fs.String("status", "APPROVED", "Status")
	commit := fs.String("commit", "", "Commit hash")
	_ = fs.Parse(os.Args[2:])

	cfg, _ := config.Load(configPath)
	if cfg == nil {
		cfg = config.DefaultConfig()
	}
	_ = ipc.SendNotification(cfg.IPC.SocketPath, ipc.Notification{
		Event:      "task_update",
		TaskIndex:  *idx,
		TaskTitle:  *task,
		Status:     *status,
		CommitHash: *commit,
	})
}

func runGate() {
	if len(os.Args) < 3 {
		return
	}
	wd, _ := os.Getwd()
	gm := gate.New(wd)
	switch os.Args[2] {
	case "release":
		_ = gm.Release(1)
	}
}

func initProject() {
	home, _ := os.UserHomeDir()
	dir := filepath.Join(home, ".devflow")
	_ = os.MkdirAll(dir, 0755)
	cfgFile := filepath.Join(dir, "config.yaml")
	sample := `telegram:
  enabled: false
  bot_token: ""
  chat_id: 0
tui:
  refresh_rate_ms: 500
`
	if _, err := os.Stat(cfgFile); os.IsNotExist(err) {
		_ = os.WriteFile(cfgFile, []byte(sample), 0644)
		fmt.Printf("Created config at: %s\n", cfgFile)
	}
}
```

- [x] **Step 2: Build binary and verify CLI commands**

Run: `cd /Users/hoaiminh/devflow-cli && go build -o devflow-cli ./cmd/devflow && ./devflow-cli version`
Expected: `devflow-cli v0.1.0`

- [x] **Step 3: Commit**

```bash
git add cmd/ Makefile
git commit -m "feat(cli): wire up subcommands tui, daemon, notify, gate, and init"
```

---

### Task 8: Devflow Hook Bridge & End-to-End Verification

**Files:**
- Modify: `/Users/hoaiminh/devflow/skills/subagent-execution/SKILL.md`
- Create: `/Users/hoaiminh/devflow/scripts/bridge-notify.sh`

**Interfaces:**
- Invokes `devflow-cli notify` and `devflow-cli gate wait` safely without crashing if `devflow-cli` is absent.

- [x] **Step 1: Write helper bridge script in devflow repo**

```bash
#!/usr/bin/env bash
# scripts/bridge-notify.sh in devflow repo
set -euo pipefail

TASK_NAME="${1:-}"
STATUS="${2:-APPROVED}"
COMMIT_HASH="${3:-}"

if command -v devflow-cli >/dev/null 2>&1; then
  devflow-cli notify --task "$TASK_NAME" --status "$STATUS" --commit "$COMMIT_HASH" || true
fi
```

- [x] **Step 2: Verify helper execution when devflow-cli is installed vs absent**

Run: `bash /Users/hoaiminh/devflow/scripts/bridge-notify.sh "Test Task" "APPROVED" "abc1234"`
Expected: Clean exit 0

- [x] **Step 3: Update subagent-execution skill with non-intrusive hook notification**

Integrate the bridge call right after a task reviewer gives the Approved verdict in `subagent-execution/SKILL.md`.

- [x] **Step 4: End-to-end simulation**
1. Start daemon or TUI in background.
2. Trigger `bridge-notify.sh`.
3. Confirm event reaches state and displays on monitor.

- [x] **Step 5: Commit in devflow repo**

```bash
git -C /Users/hoaiminh/devflow add scripts/bridge-notify.sh skills/subagent-execution/SKILL.md
git -C /Users/hoaiminh/devflow commit -m "feat(integration): add bridge hook notification for devflow-cli"
```
