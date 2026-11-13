"use client";

import { useEffect, useRef, useState } from 'react';
import { NotebookPen } from 'lucide-react';
import {
  getDraftNotes,
  setDraftNotes,
  getMeetingNotes,
  setMeetingNotes,
} from '@/lib/live-notes';

interface LiveNotesPanelProps {
  /** When set, edits the notes of a saved meeting; otherwise edits the live draft. */
  meetingId?: string;
  isRecording?: boolean;
  /** Seconds since recording start, used for the "insert timestamp" shortcut. */
  elapsedSeconds?: number;
  className?: string;
}

function formatElapsed(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds));
  const m = Math.floor(s / 60);
  return `[${m.toString().padStart(2, '0')}:${(s % 60).toString().padStart(2, '0')}]`;
}

/**
 * Plain-text notes area (Markdown allowed). Autosaves on every keystroke (debounced).
 * Ctrl+Enter inserts the current recording timestamp.
 */
export function LiveNotesPanel({ meetingId, isRecording, elapsedSeconds, className }: LiveNotesPanelProps) {
  const [text, setText] = useState('');
  const [saved, setSaved] = useState(true);
  const loadedForRef = useRef<string | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    const key = meetingId ?? '__draft__';
    if (loadedForRef.current === key) return;
    loadedForRef.current = key;
    setText(meetingId ? getMeetingNotes(meetingId) : getDraftNotes());
    setSaved(true);
  }, [meetingId]);

  // When a recording finishes, the draft is moved to the meeting – clear the local view.
  useEffect(() => {
    if (!meetingId && !isRecording) {
      setText(getDraftNotes());
    }
  }, [isRecording, meetingId]);

  useEffect(() => {
    if (saved) return;
    const t = setTimeout(() => {
      if (meetingId) setMeetingNotes(meetingId, text);
      else setDraftNotes(text);
      setSaved(true);
    }, 400);
    return () => clearTimeout(t);
  }, [text, saved, meetingId]);

  const insertTimestamp = () => {
    const el = textareaRef.current;
    if (!el || elapsedSeconds === undefined) return;
    const stamp = `${formatElapsed(elapsedSeconds)} `;
    const start = el.selectionStart;
    const next = text.slice(0, start) + stamp + text.slice(el.selectionEnd);
    setText(next);
    setSaved(false);
    requestAnimationFrame(() => {
      el.selectionStart = el.selectionEnd = start + stamp.length;
    });
  };

  return (
    <div className={`flex flex-col bg-white min-h-0 ${className ?? ''}`}>
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200">
        <div className="flex items-center gap-2 text-sm font-medium text-gray-800">
          <NotebookPen className="w-4 h-4" />
          My notes
        </div>
        <span className="text-xs text-gray-400">
          {saved ? 'Saved locally' : 'Saving…'}
        </span>
      </div>
      <textarea
        ref={textareaRef}
        aria-label="Meeting notes"
        className="flex-1 min-h-0 w-full resize-none p-4 text-sm leading-relaxed text-gray-800 focus:outline-none"
        placeholder={
          meetingId
            ? 'Your notes for this meeting. They are combined with the transcript when you (re)generate the summary.'
            : 'Type notes while you record – key points, decisions, to-dos.\nCtrl+Enter inserts the current timestamp.\nYour notes are combined with the transcript in the summary.'
        }
        value={text}
        onChange={(e) => {
          setText(e.target.value);
          setSaved(false);
        }}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && (e.ctrlKey || e.metaKey) && isRecording) {
            e.preventDefault();
            insertTimestamp();
          }
        }}
      />
    </div>
  );
}
