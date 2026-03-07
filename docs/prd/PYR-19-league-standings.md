# PRD: League Standings + Picks View

**Linear:** PYR-19
**Phase:** 1
**Status:** TODO
**Agents:** iOS Agent
**Branch:** `feature/PYR-19-league-standings`

---

## Goal

League members can see who is still alive, each member's pick for the current gameweek (post-deadline), and the full elimination history.

---

## User Story

> As a league member, I want to see who has survived each gameweek and what everyone picked, so I can follow the competition.

---

## Acceptance Criteria

### iOS — League Detail Screen

- [ ] Accessible by tapping a league in My Leagues list
- [ ] Header: league name, current gameweek, survivor count ("X of Y remaining")
- [ ] Member list sorted: active survivors first (alphabetical), then eliminated (most recently eliminated first)
- [ ] Each member row shows: display name, survival status badge (alive/eliminated), their pick for current gameweek
- [ ] Pre-deadline: picks hidden — show padlock icon instead of team name
- [ ] Post-deadline (after first match of GW kicks off): picks visible — show team name + result badge (pending / survived / eliminated)
- [ ] Eliminated members show which gameweek they were eliminated in
- [ ] Gameweek selector: tab or segmented control to view previous gameweeks' picks
- [ ] Empty state: if only 1 member (creator), show "Share your code to invite friends"
- [ ] My pick row highlighted/pinned at top if user is in the league

### Data / RLS
- [ ] Pick visibility enforced by existing RLS policies (picks hidden pre-deadline, visible post-deadline via is_locked)
- [ ] No additional migrations required

### Tests
- [ ] ViewModel: pre-deadline state (picks hidden), post-deadline state (picks visible), gameweek selector, eliminated member ordering
- [ ] 80%+ coverage

---

## Design

Figma designs required before implementation.
Key components: LeagueMemberRow, SurvivalBadge, PickBadge (pending/survived/eliminated), GameweekSelector

---

## Game Rules References

- §3.5 Pick visibility (hidden until first kick-off of GW)
- §4.1–4.2 Survival/elimination rules
- §4.5 Mass elimination (all reinstated)
- §5.2 Position determination

---

## Dependencies

- PYR-16 + PYR-17: league and member must exist
- PYR-18: picks must exist to display them
- PYR-20: settlement must run for result badges to show survived/eliminated
