#  Answers

## Questions:
### Scope & priorities                                                                                                    
   
  1. Which tranche first? The plan sequences P6 (polish) → P7 (MLB tranche A) → P8 (Savant tranche A). Is that the order
   you want, or would you rather land new endpoints first and polish later?
  2. Must-haves vs nice-to-haves for 1.0. Anything in tranches B/C you consider non-negotiable? Anything in tranche A   
  you'd drop?                                                                                                           
  3. Live game feed — is this still a priority, or has it slipped? (It has its own plan file at the repo root.)
                                                                                                                        
  Public-API decisions that shape everything downstream                                                                 
                                                                                                                        
  4. Date vs String at API boundaries — commit to Date primary with String overloads deprecated by 1.1? Or keep both    
  first-class forever?
  5. Decimal vs Double for rate stats (AVG, ERA, OPS, wOBA) — global CLAUDE.md prefers Decimal; current code uses       
  Double?. Changing this is breaking.                                                                                   
  6. Strict concurrency — OK to flip on SWIFT_STRICT_CONCURRENCY=complete and fix fallout? May surface Sendable issues
  in public types.                                                                                                      
  7. Minimum platforms at 1.0 — keep macOS 14 / iOS 17 / tvOS 17 / watchOS 10, or raise/lower? The current tag 0.1.0
  README still advertises macOS 13 / iOS 16.                                                                            
                  
  Release & distribution                                                                                                
                  
  8. Repo URL / ownership — the README points to github.com/josephskelly/SwiftBaseball. Is that the canonical public    
  URL? Will the repo be public under your personal account or a new org?
  9. License stays MIT? (Assumed yes; confirming.)                                                                      
  10. DocC hosting — GitHub Pages on the same repo, or a separate docs repo?                                            
  11. Swift Package Index submission — want me to add that to the 1.0 checklist as a blocking item?                     
                                                                                                                        
  Data-source policy                                                                                                    
                                                                                                                        
  12. Baseball Savant raw Statcast rows — pybaseball exposes the full ~100-column CSV. Do you want a 1:1 typed          
  StatcastPitch struct, or a slimmer curated subset?
  13. Rate limiting defaults for Savant — today it's single-permit. For raw multi-month pulls we'll need a chunking     
  strategy; is a hard upper bound on concurrent Savant requests (e.g. 1) acceptable for 1.0?                            
  14. Umpire scorecards endpoint — Savant's services leaderboard drifts season to season. Include behind an
  @available(*, deprecated, message: "experimental") marker, or skip for 1.0?                                           
                  
  Project management                                                                                                    
                  
  15. Work cadence — do you want one PR per tranche, or smaller per-endpoint PRs?
  16. Integration tests against live APIs — OK to keep them env-gated only, or stand up a nightly CI job that hits them?
                                                                                                                        
  Answering 1, 4, 5, 7, and 12 is the minimum to start P6 safely — the rest can wait.


Answers: 

1. This order is fine. P6 -> P7 -> P8

2. Good as is.

3. Live game feed is a nice to have. 

4. Date type is preferred. idiomatic swift.

5. Double.

6. Turn on strict concurrency.

7. Target all apple platforms, iOS, macOS, visionOS, watchOS, ipadOS, tvOS. package requirements dictates what version to target. Use Swift 6.

8. I, josephskelly, own the repo. this github origin is the canonical repo.

9. MIT license is fine. I want it as open as possible.

10. DocC hosting can be done on the same repo, if that doesn't cause any problems.

11. Yes. Swift package submission should be a blocking item for v1

12. Match pybaseball and expose the full csv

13. Yes.

14. Umpire scorecards is a nice to have. lets revisit later.

15. One PR per tranche is fine. make smaller commits though.

16. Testing against live API is ideal. I don't know how to set this up though. you'll have to walk me through it.
