/**
 * MyNotes: user-typed meeting notes.
 *
 * Notes typed during a recording are kept as a "draft" (survives reloads/crashes)
 * and are attached to the meeting ID once the recording has been saved.
 * Stored locally in the webview's localStorage – nothing leaves the machine.
 */

const DRAFT_KEY = 'mynotes:live-draft';
const MEETING_PREFIX = 'mynotes:notes:';

function safeGet(key: string): string {
  try {
    return localStorage.getItem(key) ?? '';
  } catch {
    return '';
  }
}

function safeSet(key: string, value: string): void {
  try {
    if (value.trim()) {
      localStorage.setItem(key, value);
    } else {
      localStorage.removeItem(key);
    }
  } catch {
    // storage unavailable – notes stay in memory only
  }
}

export function getDraftNotes(): string {
  return safeGet(DRAFT_KEY);
}

export function setDraftNotes(text: string): void {
  safeSet(DRAFT_KEY, text);
}

export function getMeetingNotes(meetingId: string): string {
  return safeGet(MEETING_PREFIX + meetingId);
}

export function setMeetingNotes(meetingId: string, text: string): void {
  safeSet(MEETING_PREFIX + meetingId, text);
}

/** Move the current draft onto a saved meeting. Returns the notes that were attached. */
export function claimDraftForMeeting(meetingId: string): string {
  const draft = getDraftNotes();
  if (draft.trim()) {
    const existing = getMeetingNotes(meetingId);
    setMeetingNotes(meetingId, existing ? `${existing}\n\n${draft}` : draft);
    setDraftNotes('');
  }
  return draft;
}

/** Instructions appended to every summary request so the model treats notes correctly. */
export const NOTES_AND_FACTS_RULES = [
  'The source contains two parts: <user_notes> (typed by the user during the meeting) and <transcript> (automatic speech-to-text, may contain recognition errors).',
  'Treat the user notes as the user\'s priorities: cover every point from them, and use the transcript to add context and detail.',
  'If notes and transcript conflict, prefer the user notes and mention the discrepancy briefly.',
  'Never invent facts, names, owners, or deadlines. If an action item has no explicitly stated owner write "Owner: not stated"; if it has no explicitly stated deadline write "Due: not stated".',
  'Only list a decision if it was explicitly made in the notes or transcript.',
].join('\n');

/** Combine notes and transcript into the text sent to the summarizer. */
export function buildSummarySource(transcriptText: string, notes: string): string {
  const cleanNotes = notes.trim();
  if (!cleanNotes) {
    return transcriptText;
  }
  return `<user_notes>\n${cleanNotes}\n</user_notes>\n\n<transcript>\n${transcriptText}\n</transcript>`;
}
