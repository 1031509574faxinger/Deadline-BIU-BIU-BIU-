# ================== run_pdf_image_tool_now.R ==================
# 一键：补依赖 → 检查 ImageMagick → 安装/定位 pdfImageTool_*.zip → 启动
# --------------------------------------------------------------
# 【用法（Usage）】
# 1) 交互式：在 R/RStudio 中 source('run_pdf_image_tool_now.R') 直接运行。
# 2) 命令行：Rscript run_pdf_image_tool_now.R "C:/path/pdfImageTool_*.zip"（可不带参数，脚本会在当前/桌面/下载自动查找）。
# 3) Windows 双击：若已将 .R 关联到 Rscript.exe，直接双击本文件亦可。
#
# --------------------------------------------------------------
# pdf处理很占内存，部分情况下提取图片可能失败，生成的文件会是页面提取
# --------------------------------------------------------------
# 【参数说明】
# - 本地二进制安装包 zip 的完整路径；留空则在当前目录、dist、桌面、下载智能搜索最新 zip。
#
# 【依赖与组件】
# - CRAN 包：脚本会自动补齐缺失包。
# - ImageMagick：magick 的系统依赖，本脚本会检查；未安装将给出平台化指引（Windows/macOS/Linux）。
# - 可选组件：Ghostscript（PDF 压缩链），Poppler/pdfimages（某些工作流可能用到）。它们不是本脚本的强制依赖。
#
# 【常见问题（Troubleshooting）】
# - 未检测到 ImageMagick：
#   * Windows：安装官方包，并在安装器中勾选 `Install development headers` 与 `Install legacy utilities`；建议 64 位且与 R 位数一致；装完重启 R。
#   * macOS：brew install imagemagick；Linux：使用发行版包管理器安装 imagemagick。
# - 找不到 zip：将打包好的 zip 放到 当前目录/dist/桌面/下载 中之一，或将路径作为命令行参数传入。
# - 没权限安装到系统库：R 会安装到你的用户库（无需管理员权限）。
#
# 【安全与隐私】
# - 本脚本仅在需要时从 CRAN 下载缺失 R 包；不读取或上传你的任何文档。
# - 处理的 PDF/图片均在本机完成；输出内容的版权与合规由你自行负责。
#
# 【记录与卸载】
# - 安装的包位于用户库（.libPaths()[1]）；卸载可用 remove.packages('pdfImageTool')。
# --------------------------------------------------------------
local({
  if (is.null(getOption('repos')) || is.na(getOption('repos')['CRAN']))
    options(repos = c(CRAN = 'https://cloud.r-project.org'))
  options(install.packages.compile.from.source = 'never')
  Sys.setenv(R_INSTALL_STAGED = 'false')

  need_im <- function(){
    if (requireNamespace('magick', quietly = TRUE)) return(FALSE)
    hits <- Sys.which(c('magick','magick.exe','convert','convert.exe'))
    all(nchar(hits) == 0)
  }
  if (need_im()) {
    os <- Sys.info()[['sysname']]
    if (identical(os,'Windows')) stop(
      paste(
        '未检测到 ImageMagick（magick 的系统依赖）。请先安装：',
        '- 下载：https://imagemagick.org/script/download.php#windows',
        '- 安装时勾选：Install development headers、Install legacy utilities',
        '- 建议 64 位，与 R 位数一致；安装后重启 R 再运行本脚本。', sep='\n'),
      call. = FALSE)
    else stop(
      paste(
        '未检测到 ImageMagick。请先安装后重试：',
        '- macOS: brew install imagemagick',
        '- Linux: 使用发行版包管理器安装 imagemagick',
        '- 官网：https://imagemagick.org', sep='\n'),
      call. = FALSE)
  }

  deps <- c('bslib','colorspace','digest','htmltools','jquerylib','magick','pdftools','sass','shiny','shinyFiles','sortable','tools')
  need <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]
  if (length(need)) install.packages(need, dependencies = TRUE)
  invisible(lapply(deps, require, character.only = TRUE))

  pkg <- 'pdfImageTool'
  if (!requireNamespace(pkg, quietly = TRUE)) {
    args <- commandArgs(trailingOnly = TRUE)
    cand <- if (length(args) >= 1 && nzchar(args[1])) args[1] else character(0)
    if (!length(cand)) {
      here <- getwd(); home <- path.expand('~')
      guesses <- c(file.path(here, sprintf('%s_*.zip', pkg)),
                   file.path(here, 'dist', sprintf('%s_*.zip', pkg)),
                   file.path(home, 'Desktop',  sprintf('%s_*.zip', pkg)),
                   file.path(home, 'Downloads',sprintf('%s_*.zip', pkg)))
      found <- unique(unlist(lapply(guesses, Sys.glob)))
      if (length(found)) cand <- found[order(file.info(found)$mtime, decreasing = TRUE)][1]
    }
    if (!length(cand) || !file.exists(cand))
      stop('未找到 ', pkg, '_*.zip；请放到当前/dist/桌面/下载，或在命令行参数传入路径。', call. = FALSE)
    install.packages(cand, repos = NULL, type = 'win.binary')
  }

  library(pdfImageTool)
  if (exists('run_pdf_image_tool', asNamespace('pdfImageTool'), inherits = FALSE)) {
    pdfImageTool:::run_pdf_image_tool()
  } else if (exists('run_pdf_image_tool')) {
    run_pdf_image_tool()
  } else {
    stop('包内未找到 run_pdf_image_tool()。请确认函数存在且已导出。', call. = FALSE)
  }
})

