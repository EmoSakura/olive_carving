# Supabase 接入说明

本文档说明如何把榄雕云艺项目从本地模拟后台切换为真实 Supabase 后端。

## 当前已接入的能力

- 邮箱密码登录
- 用户注册
- 会话恢复
- 管理后台的展品发布状态
- 首页精选位管理

未配置 Supabase 时，项目会自动回退到本地演示模式。

## 1. 创建 Supabase 项目

在 Supabase 控制台创建一个新项目，记下：

- Project URL
- Publishable key

说明：

- 新版 Supabase 客户端常见的是 `sb_publishable_...`
- 在 Flutter 代码里仍然会传给 `anonKey` 参数，这是正常的

## 2. 配置项目

### 方式 A：直接编辑本地配置文件

项目已内置配置文件：

`assets/config/supabase_config.json`

把其中内容改成：

```json
{
  "supabaseUrl": "你的项目URL",
  "supabaseAnonKey": "你的PublishableKey"
}
```

保存后重新运行项目即可。未填写时会自动回退到本地演示模式。

### 方式 B：使用命令行参数

如果你不想把配置写进文件，也可以继续使用 `--dart-define`。

#### Windows 桌面

```bash
flutter run -d windows --dart-define=SUPABASE_URL=你的项目URL --dart-define=SUPABASE_ANON_KEY=你的PublishableKey
```

#### Chrome Web

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=你的项目URL --dart-define=SUPABASE_ANON_KEY=你的PublishableKey
```

#### Windows Release 构建

```bash
flutter build windows --dart-define=SUPABASE_URL=你的项目URL --dart-define=SUPABASE_ANON_KEY=你的PublishableKey
```

## 3. 创建内容管理表

在 SQL Editor 执行：

```sql
create table if not exists public.managed_exhibits (
  exhibit_id text primary key,
  featured boolean not null default false,
  published boolean not null default true,
  admin_tag text not null default '未标记',
  updated_at timestamp with time zone not null default now()
);

alter table public.managed_exhibits enable row level security;

drop policy if exists "Managed exhibits readable by authenticated users"
on public.managed_exhibits;

drop policy if exists "Managed exhibits writable by admins"
on public.managed_exhibits;

create policy "Managed exhibits readable by authenticated users"
on public.managed_exhibits
for select
to authenticated
using (true);

create policy "Managed exhibits writable by admins"
on public.managed_exhibits
for all
to authenticated
using (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
)
with check (
  (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  or (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);
```

这版 SQL 可以重复执行，不会因为策略已存在而报错卡住。

## 4. 注册与登录建议

项目已经支持应用内注册和登录。

### 快速演示方案

建议先关闭 Supabase 的邮箱确认：

- `Authentication -> Providers -> Email`
- 关闭 `Confirm email` 或类似开关

这样用户注册后可直接进入系统，不会被邮件验证卡住。

### 如果仍然需要邮箱确认

需要注意：

- Supabase 默认 SMTP 对外部邮箱发送能力有限
- 如果未配置自定义 SMTP，外部用户可能收不到验证邮件

如果你要正式对外开放注册，建议后续补上自定义 SMTP。

## 5. 推荐测试账号

建议先准备两个账号：

- 管理员：`admin@olive.art`
- 访客：`guest@olive.art`

如果要让管理员账号在应用内自动看到后台页，建议给管理员用户设置 `role=admin`。

可在 SQL Editor 执行：

```sql
update auth.users
set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"role":"admin","display_name":"项目管理员"}'::jsonb
where email = 'admin@olive.art';

update auth.users
set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"role":"visitor","display_name":"访客用户"}'::jsonb
where email = 'guest@olive.art';
```

## 6. 当前实现边界

当前真实接入的后端能力主要集中在：

- 注册认证
- 登录认证
- 会话恢复
- 管理后台展品发布状态
- 首页精选位控制

这些状态还没有全部同步到独立 CMS，也还没有把用户收藏、学习进度、互动归档上传到云端。

如果下一步继续推进，优先建议做：

1. 用户收藏与互动记录上云
2. 内容表从本地 JSON 迁移到 Supabase
3. 管理后台支持编辑正文、图片与标签
