# Build Instructions — Figma Prompt Generator for macOS

## Project Name

Figma Prompt Generator

---

# Goal

Build a native macOS application that transforms Figma screenshots, design references, CSS inspection exports, and design notes into high-quality implementation prompts for AI coding agents.

The application should automate the exact workflow currently used by the user when creating prompts for:

- Cursor
- Claude Code
- GPT-5
- Lovable
- Bolt
- V0
- Windsurf
- Devin

The generated prompts should be production-quality and follow the standards defined in the provided Instructions.md.

---

# Core User Flow

## Step 1

User drags or pastes a screenshot from Figma.

Supported formats:

- PNG
- JPG
- JPEG
- WEBP

---

## Step 2

User pastes optional Figma Inspect CSS.

Large CSS blocks should be supported.

---

## Step 3

User optionally adds notes.

Examples:

- "This should be the Hero section"
- "Reuse the CTA"
- "Add premium animations"
- "This belongs under Products"

---

## Step 4

User clicks:

Generate Prompt

---

## Step 5

The application sends:

- Image
- CSS
- Notes
- Instructions.md

to an LLM.

---

## Step 6

The LLM returns:

A fully formatted implementation prompt.

---

## Step 7

User can:

- Copy Prompt
- Save Prompt
- Export Prompt
- Refine Prompt

---

# Technical Stack

## Application

Native macOS App

Recommended:

SwiftUI

Reasons:

- Native performance
- Native drag and drop
- Native image paste support
- Native file management
- Modern UI

---

## Architecture

MVVM

Structure:

Views/
ViewModels/
Models/
Services/
Storage/
Components/

---

# Features

## 1. Image Upload

Support:

### Drag and Drop

User drags image into app.

### Clipboard Paste

CMD + V

### File Picker

Import image manually.

---

## 2. CSS Input

Large text editor.

Requirements:

- Syntax highlighting
- Scrollable
- Auto resize

---

## 3. Notes Input

Multi-line text editor.

Examples:

- Add animations
- Create hero section
- Reuse footer

---

## 4. Prompt Preview

Large output area.

Display generated prompt.

Support:

- Markdown rendering
- Raw text view

---

## 5. Copy Button

Copies generated prompt.

---

## 6. Export Button

Export:

- TXT
- MD

---

## 7. History

Store previous prompts locally.

Show:

- Screenshot thumbnail
- Date
- Prompt title

---

## 8. Prompt Templates

User can select:

### Generic

### Hero Section

### Features Section

### Pricing Section

### CTA Section

### Footer Section

### Product Page

### Landing Page

### Industry Page

### Bento Grid

### Dashboard Showcase

The selected template influences generation.

---

# AI Integration

## Model

Use OpenAI Responses API.

Recommended:

GPT-5

---

# Prompt Pipeline

System Prompt:

Load Instructions.md.

User Message:

Contains:

- Uploaded image
- CSS
- Notes

The Instructions.md acts as the generation framework.

---

# Analysis Requirements

Before generating prompts the AI should:

Analyze:

### Layout

- Hero
- Features
- CTA
- Footer
- Pricing
- Bento Grid

### Typography

- Headings
- Labels
- Paragraphs

### Colors

- Background
- Accent
- CTA

### Images

- Product screenshots
- People
- Illustrations

### Decorative Elements

- SVGs
- Pixel blocks
- Patterns

### Existing Components

- Buttons
- Cards
- Navigation

---

# Generated Prompt Quality

Every prompt must include:

## Objective

## Layout

## Content

## Visual Style

## Animations

## Hover Effects

## Responsive Behavior

## Reuse Existing Components

## Design Goals

## Acceptance Criteria

---

# UI Design

Follow the aesthetic of:

- Raycast
- Linear
- Vercel
- Arc Browser

Theme:

Dark

Primary Color:

#00280E

Accent:

#9CA703

Text:

#FAF9F0

Cards:

#031E0C

Radius:

16px

---

# Main Screen Layout

-------------------------------------------------

[ Sidebar ]

History
Templates
Settings

-------------------------------------------------

[ Main Content ]

Image Upload

CSS Input

Notes Input

Generate Button

-------------------------------------------------

[ Output ]

Generated Prompt

Copy

Export

-------------------------------------------------

# Settings Screen

Allow:

### OpenAI API Key

Store securely in Keychain.

### Default Model

- GPT-5
- GPT-5 Mini

### Temperature

### Max Tokens

---

# Local Storage

Persist:

- Prompt History
- User Preferences
- Recent Images

Use:

SwiftData

---

# Performance Requirements

Must handle:

- Large screenshots
- Long CSS blocks
- Multiple generations

Target:

< 3 seconds UI response time.

---

# Future Features

Phase 2:

### Multiple Images

Allow multiple screenshots.

### Entire Page Analysis

Generate prompts for:

- Entire landing pages
- Multi-section websites

### Figma JSON Import

Paste Figma JSON.

### MCP Integration

Connect directly to Figma MCP.

### Prompt Refinement

"Improve Prompt"

button.

### Section Detection

Automatically detect:

- Hero
- Pricing
- CTA
- Footer

without user input.

---

# Acceptance Criteria

✓ Native macOS application

✓ SwiftUI implementation

✓ Drag and drop image support

✓ Paste image support

✓ CSS support

✓ Notes support

✓ OpenAI integration

✓ Uses Instructions.md as generation framework

✓ Prompt history

✓ Export functionality

✓ Production-ready architecture

✓ Modern premium UI

✓ Optimized for prompt generation workflows

✓ Ready for App Store distribution
