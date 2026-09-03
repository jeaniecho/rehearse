import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../theme/app_theme.dart';

const scenarios = <Scenario>[
  Scenario(
    id: 'missed-deadlines',
    title: 'The slipping deadline',
    subtitle: 'Address repeated missed commitments without losing trust.',
    skill: 'Clear feedback',
    durationMinutes: 4,
    stakes: ScenarioStakes.challenging,
    icon: Icons.schedule_rounded,
    emoji: '⏰',
    tint: AppColors.subtle,
    personName: 'Jordan Lee',
    personRole: 'Senior product designer',
    personInitials: 'JL',
    context:
        'Jordan has missed two design handoffs this month. The engineering team is blocked, but Jordan has also been covering for an open role.',
    goal:
        'Name the pattern, understand what is getting in the way, and agree on a concrete next step.',
    watchFor:
        'Do not soften the expectation so much that the impact becomes unclear.',
    openingLine:
        'Honestly, I’m surprised we’re talking about this. I’ve been carrying two roles for the last month.',
    turns: [
      DialogueTurn(
        employeeLine:
            'Honestly, I’m surprised we’re talking about this. I’ve been carrying two roles for the last month.',
        prompt: 'How do you open?',
        choices: [
          ResponseChoice(
            text:
                'You’re right—it’s been a lot. Let’s forget the deadlines for now.',
            scoreDelta: -8,
            feedback:
                'You acknowledged the pressure, but removed the expectation entirely.',
            clarity: -2,
            empathy: 2,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text:
                'I see how much you’ve taken on. I also need us to address the two missed handoffs and their impact.',
            scoreDelta: 14,
            feedback:
                'Strong opening: you held empathy and accountability at the same time.',
            clarity: 2,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'Everyone is stretched. Missing deadlines at your level isn’t acceptable.',
            scoreDelta: -2,
            feedback:
                'The standard is clear, but the opening may make Jordan defensive.',
            clarity: 2,
            empathy: -2,
            directness: 1,
            confidence: 1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Engineering changes the scope constantly. I can’t commit to a date when the target keeps moving.',
        prompt: 'Jordan pushes back. What next?',
        choices: [
          ResponseChoice(
            text:
                'What part of the changing scope is creating the biggest risk?',
            scoreDelta: 10,
            feedback:
                'Good diagnosis. You stayed curious without abandoning the issue.',
            clarity: 1,
            empathy: 2,
            directness: 1,
            confidence: 1,
          ),
          ResponseChoice(
            text:
                'That sounds like an excuse. You still need to communicate sooner.',
            scoreDelta: -5,
            feedback:
                'There is a useful expectation here, but dismissing the concern shuts down candor.',
            clarity: 2,
            empathy: -2,
            directness: 1,
            confidence: 0,
          ),
          ResponseChoice(
            text: 'Okay. I’ll speak to engineering and sort it out for you.',
            scoreDelta: -4,
            feedback:
                'You took ownership away from Jordan before clarifying what support is needed.',
            clarity: -1,
            empathy: 1,
            directness: -1,
            confidence: -1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'I can flag risk earlier, but I can’t promise the Friday handoff unless something else moves.',
        prompt: 'Close with a clear agreement.',
        choices: [
          ResponseChoice(
            text:
                'Let’s pick the tradeoff now. Which task moves, and when will you flag any new risk?',
            scoreDelta: 14,
            feedback:
                'Specific and shared: you turned the tension into an observable agreement.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Just do your best and keep me posted.',
            scoreDelta: -8,
            feedback:
                'Supportive, but too vague to change the pattern you came to discuss.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'Friday is the deadline. I expect you to figure it out.',
            scoreDelta: -3,
            feedback:
                'You held the line, but ignored a credible capacity constraint.',
            clarity: 2,
            empathy: -2,
            directness: 1,
            confidence: 1,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'say-no',
    title: 'The impossible request',
    subtitle: 'Say no to your director while protecting the relationship.',
    skill: 'Boundaries',
    durationMinutes: 3,
    stakes: ScenarioStakes.highStakes,
    icon: Icons.shield_outlined,
    emoji: '🛑',
    tint: AppColors.subtle,
    personName: 'Maya Chen',
    personRole: 'Director of marketing',
    personInitials: 'MC',
    context:
        'Maya wants your team to launch a customer webinar in ten days. Your team is already committed to the annual campaign.',
    goal:
        'Decline the current scope clearly and offer a realistic path forward.',
    watchFor:
        'Avoid a vague “we’ll try” that silently transfers the cost to your team.',
    openingLine:
        'This webinar is now the top priority. I need your team to make it happen by next Friday.',
    turns: [
      DialogueTurn(
        employeeLine:
            'This webinar is now the top priority. I need your team to make it happen by next Friday.',
        prompt: 'How do you respond?',
        choices: [
          ResponseChoice(
            text:
                'We can do it, but the annual campaign would move by two weeks. Is that the tradeoff you want?',
            scoreDelta: 14,
            feedback:
                'You made the constraint visible and put the priority decision at the right level.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'We’ll do our best. I’ll see what the team can pull together.',
            scoreDelta: -8,
            feedback:
                'This sounds agreeable, but it hides the delivery risk and overcommits the team.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'No. That timeline is completely unrealistic.',
            scoreDelta: -2,
            feedback:
                'The boundary is unmistakable, but you have not helped Maya make a next decision.',
            clarity: 2,
            empathy: -2,
            directness: 2,
            confidence: 2,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'The CEO already announced it. Moving the webinar is not an option.',
        prompt: 'The pressure rises.',
        choices: [
          ResponseChoice(
            text:
                'Then I recommend a smaller webinar: one speaker, existing creative, and no new campaign assets.',
            scoreDelta: 12,
            feedback:
                'You respected the constraint and offered a viable reduction in scope.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Fine. I’ll tell the team they need to work late.',
            scoreDelta: -10,
            feedback:
                'You passed pressure downstream without testing scope or protecting the team.',
            clarity: 0,
            empathy: -2,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'Why was this announced before anyone checked with us?',
            scoreDelta: -4,
            feedback:
                'A fair process question, but it pulls focus away from the decision needed now.',
            clarity: -1,
            empathy: -1,
            directness: 1,
            confidence: -1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'The smaller format could work. Send me the exact scope by this afternoon.',
        prompt: 'Lock in the agreement.',
        choices: [
          ResponseChoice(
            text:
                'I’ll send a one-page scope by 3 p.m. Once approved, we’ll hold the Friday date with those limits.',
            scoreDelta: 14,
            feedback:
                'A crisp close with owner, timing, decision point, and boundary.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Great, I’ll get something over to you soon.',
            scoreDelta: -5,
            feedback:
                'Positive, but “something” and “soon” leave the agreement exposed.',
            clarity: -2,
            empathy: 1,
            directness: -1,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'Okay, but I want it noted that this still isn’t realistic.',
            scoreDelta: -3,
            feedback:
                'You re-opened the conflict after finding a workable path.',
            clarity: 0,
            empathy: -1,
            directness: 0,
            confidence: -1,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'peer-conflict',
    title: 'The tense teammate',
    subtitle: 'Reset a strained relationship after a heated meeting.',
    skill: 'Repair & trust',
    durationMinutes: 4,
    stakes: ScenarioStakes.warmUp,
    icon: Icons.handshake_outlined,
    emoji: '⚡',
    tint: AppColors.subtle,
    personName: 'Alex Morgan',
    personRole: 'Engineering lead',
    personInitials: 'AM',
    context:
        'You interrupted Alex twice in a planning meeting. Alex then criticized your proposal sharply in front of the group.',
    goal:
        'Own your part, surface the impact, and agree on how to disagree productively.',
    watchFor:
        'An apology followed by “but” usually sounds like a defense, not repair.',
    openingLine:
        'If this is about the meeting, I don’t have much to add. You clearly weren’t listening to me.',
    turns: [
      DialogueTurn(
        employeeLine:
            'If this is about the meeting, I don’t have much to add. You clearly weren’t listening to me.',
        prompt: 'Start the repair.',
        choices: [
          ResponseChoice(
            text:
                'You’re right that I interrupted you. I’m sorry. I want to understand what impact that had.',
            scoreDelta: 14,
            feedback:
                'You owned the specific behavior without defending it and invited Alex’s perspective.',
            clarity: 2,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'I’m sorry, but you were also pretty aggressive in that meeting.',
            scoreDelta: -6,
            feedback:
                'The “but” turns the apology into a countercharge before repair has started.',
            clarity: 0,
            empathy: -2,
            directness: 0,
            confidence: -1,
          ),
          ResponseChoice(
            text: 'I think we both got a little carried away.',
            scoreDelta: -4,
            feedback:
                'This lowers the temperature, but blurs your ownership of what happened.',
            clarity: -1,
            empathy: 1,
            directness: -1,
            confidence: -1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'It made me feel like the decision was already made and my input was just for show.',
        prompt: 'What do you say?',
        choices: [
          ResponseChoice(
            text:
                'I can see why it landed that way. The decision wasn’t made, but my behavior suggested it was.',
            scoreDelta: 12,
            feedback:
                'You separated intent from impact without arguing with Alex’s experience.',
            clarity: 1,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'That wasn’t my intention at all. You misunderstood me.',
            scoreDelta: -7,
            feedback:
                'Explaining intent too soon invalidates the impact Alex just shared.',
            clarity: 0,
            empathy: -2,
            directness: -1,
            confidence: -1,
          ),
          ResponseChoice(
            text: 'I hear you.',
            scoreDelta: 0,
            feedback:
                'A calm acknowledgment, though it stops short of showing what you understood.',
            clarity: -1,
            empathy: 1,
            directness: 0,
            confidence: 0,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'I don’t want us walking on eggshells. I just need room to finish the point.',
        prompt: 'Agree on a reset.',
        choices: [
          ResponseChoice(
            text:
                'Agreed. I’ll pause before responding and make sure you’ve finished. If I slip, call it in the moment.',
            scoreDelta: 14,
            feedback:
                'The reset is concrete, reciprocal, and easy to use in the next meeting.',
            clarity: 2,
            empathy: 2,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Absolutely. Let’s just start fresh next time.',
            scoreDelta: -3,
            feedback:
                'Warm, but there is no behavioral change to make “fresh” feel different.',
            clarity: -2,
            empathy: 1,
            directness: -1,
            confidence: -1,
          ),
          ResponseChoice(
            text: 'Sure—as long as you keep the criticism constructive too.',
            scoreDelta: -2,
            feedback:
                'The request is valid, but the conditional framing makes the repair transactional.',
            clarity: 1,
            empathy: -1,
            directness: 1,
            confidence: 0,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'upward-feedback',
    title: 'The feedback upward',
    subtitle: 'Tell your own manager something they will not enjoy hearing.',
    skill: 'Upward candor',
    durationMinutes: 4,
    stakes: ScenarioStakes.highStakes,
    icon: Icons.record_voice_over_outlined,
    emoji: '🗣️',
    tint: AppColors.subtle,
    personName: 'Priya Raman',
    personRole: 'VP of engineering',
    personInitials: 'PR',
    context:
        'Priya has reversed three of your team’s decisions in a public channel after the team had already committed to them. People have stopped proposing anything.',
    goal:
        'Name the pattern and its effect on the team without turning it into a verdict on Priya.',
    watchFor:
        'Hedging so heavily that Priya hears a compliment instead of feedback.',
    openingLine:
        'You wanted time? I’ve got ten minutes before my next thing. What’s up?',
    turns: [
      DialogueTurn(
        employeeLine:
            'You wanted time? I’ve got ten minutes before my next thing. What’s up?',
        prompt: 'Ten minutes. How do you start?',
        choices: [
          ResponseChoice(
            text:
                'I want to raise something about how decisions land. In the last two sprints, three were reversed in channel after we’d committed.',
            scoreDelta: 14,
            feedback:
                'You led with the observable pattern instead of a judgment, which makes it discussable.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'Nothing major. I just wanted to check in on how you think the team is doing.',
            scoreDelta: -8,
            feedback:
                'You booked the time and then gave the issue away. Priya will leave without knowing anything was wrong.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text:
                'You keep overruling us in public and it’s demoralizing the whole team.',
            scoreDelta: -3,
            feedback:
                'The courage is real, but “you keep” and “the whole team” invite an argument about whether that’s true.',
            clarity: 1,
            empathy: -2,
            directness: 2,
            confidence: 0,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'I reversed them because they were wrong. Would you rather I let a bad call ship?',
        prompt: 'Priya pushes back.',
        choices: [
          ResponseChoice(
            text:
                'No, I want the corrections. It’s where they land. In channel, after we’ve committed, the team reads it as their judgment not being trusted.',
            scoreDelta: 12,
            feedback:
                'You conceded the real point and kept the actual one, which is the venue rather than the veto.',
            clarity: 2,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'That’s fair. Maybe I’m reading more into it than is really there.',
            scoreDelta: -8,
            feedback:
                'One question was enough to make you withdraw the feedback. Priya now believes there was nothing to it.',
            clarity: -2,
            empathy: 0,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text:
                'They weren’t wrong, though. That’s the part I’d actually push back on.',
            scoreDelta: -5,
            feedback:
                'You traded a conversation about how decisions land for a debate about three old ones.',
            clarity: -1,
            empathy: -1,
            directness: 1,
            confidence: 0,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Alright. So what would you have me do differently — say nothing?',
        prompt: 'Give Priya something she can use.',
        choices: [
          ResponseChoice(
            text:
                'Send it to me first. I’ll take the reversal to the team myself the same day. You keep the call; they stop learning it in public.',
            scoreDelta: 14,
            feedback:
                'A specific mechanism that costs Priya nothing she cares about. That is what makes upward feedback survivable.',
            clarity: 2,
            empathy: 2,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'No, not at all. I just wanted to flag it. You know the wider picture better than I do.',
            scoreDelta: -8,
            feedback:
                'The retreat at the end undoes the work of raising it at all.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'Just stop posting decisions in the channel.',
            scoreDelta: -3,
            feedback:
                'A clear ask, but stated as an instruction to your own manager with no reasoning attached.',
            clarity: 2,
            empathy: -2,
            directness: 1,
            confidence: 0,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'promotion-denied',
    title: 'The promotion that isn’t',
    subtitle: 'Deliver a no to someone who was expecting a yes.',
    skill: 'Hard news',
    durationMinutes: 4,
    stakes: ScenarioStakes.highStakes,
    icon: Icons.workspace_premium_outlined,
    emoji: '🪜',
    tint: AppColors.subtle,
    personName: 'Sam Okafor',
    personRole: 'Senior engineer',
    personInitials: 'SO',
    context:
        'You told Sam in January that this promotion was very likely. The committee said no on scope of influence. Sam has already told their family.',
    goal:
        'Deliver the decision plainly, own the expectation you set, and make the path real or admit there isn’t one yet.',
    watchFor:
        'Hiding behind “the committee” so the decision has no owner in the room.',
    openingLine: 'So — is it done? I’ve been refreshing my inbox all morning.',
    turns: [
      DialogueTurn(
        employeeLine:
            'So — is it done? I’ve been refreshing my inbox all morning.',
        prompt: 'Sam is expecting a yes.',
        choices: [
          ResponseChoice(
            text:
                'It’s a no this cycle, Sam. I want to say that clearly before anything else, and I want to own that I told you it was likely.',
            scoreDelta: 14,
            feedback:
                'You gave the answer in the first sentence and took the expectation with it. Nothing else you say has to fight the suspense.',
            clarity: 2,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'It’s… complicated. There was a lot for the committee to weigh this round.',
            scoreDelta: -8,
            feedback:
                'Sam already knows the answer from your tone. Delaying it just makes them wait for it.',
            clarity: -2,
            empathy: -1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text:
                'The committee didn’t approve it. It was genuinely out of my hands.',
            scoreDelta: -4,
            feedback:
                'Clear, but you stepped out of the decision. Sam now has bad news and nobody to talk to about it.',
            clarity: 1,
            empathy: -2,
            directness: -2,
            confidence: -2,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'You told me in January this was basically done. What changed?',
        prompt: 'The expectation you set is now the subject.',
        choices: [
          ResponseChoice(
            text:
                'Nothing about your work changed. My read of the bar was wrong, and I passed that on to you as a promise. That part is on me.',
            scoreDelta: 12,
            feedback:
                'Separating your error from Sam’s performance is the single most useful thing you can do here.',
            clarity: 2,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'These rounds are always a bit unpredictable. You know how it goes.',
            scoreDelta: -7,
            feedback:
                'Treating a promise you made as weather leaves Sam with nothing to trust next time.',
            clarity: -2,
            empathy: -1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'I said likely, not certain. There is a difference.',
            scoreDelta: -6,
            feedback:
                'Accurate and useless. You won the wording and lost the person.',
            clarity: 1,
            empathy: -2,
            directness: 0,
            confidence: -1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Fine. So what do I actually do between now and the next cycle?',
        prompt: 'Make the path concrete.',
        choices: [
          ResponseChoice(
            text:
                'Two things the committee named: lead a cross-team project end to end, and write design reviews other teams cite. I’ll find you the first one this month.',
            scoreDelta: 14,
            feedback:
                'Named gaps, a named owner, and a date. This is the difference between a no and a plan.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Keep doing what you’re doing. It’ll come around.',
            scoreDelta: -8,
            feedback:
                'If the current work were enough, the answer would have been yes. This tells Sam nothing.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text:
                'Nail the next six months and I’ll make sure it goes through.',
            scoreDelta: -4,
            feedback:
                'You just made the same promise that caused this conversation.',
            clarity: 0,
            empathy: 1,
            directness: -2,
            confidence: -1,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'high-performer',
    title: 'The brilliant difficult one',
    subtitle: 'Confront behavior from someone you cannot afford to lose.',
    skill: 'Standards',
    durationMinutes: 4,
    stakes: ScenarioStakes.challenging,
    icon: Icons.diamond_outlined,
    emoji: '💎',
    tint: AppColors.subtle,
    personName: 'Ravi Deshpande',
    personRole: 'Principal analyst',
    personInitials: 'RD',
    context:
        'Ravi ships more than anyone on the team and is brutal in review. Two people have now asked not to be paired with him.',
    goal:
        'Make the behavior a performance issue rather than a personality note, and say what happens if it continues.',
    watchFor:
        'Trading the standard away because the output is genuinely excellent.',
    openingLine:
        'Let me guess — someone complained again. My work speaks for itself.',
    turns: [
      DialogueTurn(
        employeeLine:
            'Let me guess — someone complained again. My work speaks for itself.',
        prompt: 'Ravi opens defensively.',
        choices: [
          ResponseChoice(
            text:
                'Your work is excellent and it isn’t what we’re here about. Two people have asked not to work with you. That’s a performance problem, and it’s the one we’re solving.',
            scoreDelta: 14,
            feedback:
                'Granting the quality first removes his best argument, then you named the real cost in facts he can’t wave off.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'Nobody’s complaining exactly. I just wanted to check in on how reviews have been going.',
            scoreDelta: -8,
            feedback:
                'Opening with a false premise means anything true you say afterwards arrives as an ambush.',
            clarity: -2,
            empathy: 0,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'Your attitude is the problem, and everyone knows it.',
            scoreDelta: -4,
            feedback:
                'Attitude isn’t observable and “everyone” isn’t a witness. Ravi can argue with both.',
            clarity: -1,
            empathy: -2,
            directness: 2,
            confidence: 0,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'So I’m supposed to pretend bad work is fine to protect people’s feelings?',
        prompt: 'He has set a trap. Step around it.',
        choices: [
          ResponseChoice(
            text:
                'No. Say the work is wrong — say it about the work. “This query double-counts refunds” lands. “Did you even read the spec” doesn’t.',
            scoreDelta: 12,
            feedback:
                'You refused the false choice and replaced it with two sentences he can actually copy.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'I’m not asking you to lower the bar, obviously. Maybe just soften it a bit?',
            scoreDelta: -6,
            feedback:
                '“Soften it” is not something anyone can act on, and it concedes that the bar and the behavior are linked.',
            clarity: -2,
            empathy: 1,
            directness: -1,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'I’m asking you to be less of a problem in meetings.',
            scoreDelta: -5,
            feedback:
                'You made him the problem rather than the behavior, which is exactly the fight he was inviting.',
            clarity: 0,
            empathy: -2,
            directness: 1,
            confidence: 0,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine: 'And if I don’t get this right? What happens then?',
        prompt: 'He is asking whether you mean it.',
        choices: [
          ResponseChoice(
            text:
                'It goes in your review and the pairing requests stand. I’d rather that didn’t happen — I’ll sit in on your next two reviews and give you the read afterwards.',
            scoreDelta: 14,
            feedback:
                'A real consequence and real support in the same breath. He now knows the standard is not negotiable and that you are not against him.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Let’s not get ahead of ourselves. I’m sure it’ll be fine.',
            scoreDelta: -8,
            feedback:
                'He asked the only question that mattered and you told him nothing happens.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'Then we’ll be having a very different conversation.',
            scoreDelta: -3,
            feedback:
                'Ominous but empty. A consequence he can’t picture isn’t one.',
            clarity: -1,
            empathy: -1,
            directness: 2,
            confidence: 1,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'resignation',
    title: 'The notice you didn’t see coming',
    subtitle: 'Hear a resignation without turning it into a negotiation.',
    skill: 'Listening',
    durationMinutes: 3,
    stakes: ScenarioStakes.warmUp,
    icon: Icons.waving_hand_outlined,
    emoji: '🚪',
    tint: AppColors.subtle,
    personName: 'Nadia Haddad',
    personRole: 'Product manager',
    personInitials: 'NH',
    context:
        'Nadia has been here three years and is one of your steadiest people. She has asked for ten minutes and you have no idea why.',
    goal:
        'Understand what actually drove the decision before deciding whether anything is worth offering.',
    watchFor:
        'A counteroffer in the first two minutes tells Nadia the conversation is about you.',
    openingLine:
        'I wanted you to hear it from me first. I’ve accepted an offer somewhere else.',
    turns: [
      DialogueTurn(
        employeeLine:
            'I wanted you to hear it from me first. I’ve accepted an offer somewhere else.',
        prompt: 'You did not see this coming.',
        choices: [
          ResponseChoice(
            text:
                'Thank you for telling me directly. Before anything else — how long have you been sitting with this?',
            scoreDelta: 14,
            feedback:
                'You bought yourself the whole conversation with one question instead of spending it on a reaction.',
            clarity: 1,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Before you sign anything, let me see what I can do on comp.',
            scoreDelta: -8,
            feedback:
                'A counteroffer this fast says you would rather solve it than understand it.',
            clarity: 0,
            empathy: -2,
            directness: -1,
            confidence: -1,
          ),
          ResponseChoice(
            text: 'Wow. Okay. Well — I appreciate the notice, I suppose.',
            scoreDelta: -6,
            feedback:
                'Understandable, and it ends the conversation. Nadia now has to manage your reaction instead of telling you anything.',
            clarity: -1,
            empathy: -2,
            directness: -2,
            confidence: -2,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'A few months. It isn’t really about money — I stopped learning anything new here about a year ago.',
        prompt: 'She has told you the real reason.',
        choices: [
          ResponseChoice(
            text:
                'A year is a long time to feel that and not say it. What did I miss, or what made it hard to bring up?',
            scoreDelta: 12,
            feedback:
                'You asked about your own part without making her comfort you. That is where the useful answer lives.',
            clarity: 2,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'You could have come to me. I’d have found you something new.',
            scoreDelta: -7,
            feedback:
                'True and beside the point. She just told you she didn’t feel she could, and you answered that she should have.',
            clarity: 1,
            empathy: -2,
            directness: 0,
            confidence: 0,
          ),
          ResponseChoice(
            text: 'That’s completely understandable. These things happen.',
            scoreDelta: -5,
            feedback:
                'Gracious, but it closes the door on the one piece of information you actually need.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: 0,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Honestly? You were always busy. It never felt like the right week.',
        prompt: 'That one lands. What now?',
        choices: [
          ResponseChoice(
            text:
                'That’s fair, and I’ll fix it for whoever’s next. For your last month: tell me what you want to hand over well and I’ll clear the rest.',
            scoreDelta: 14,
            feedback:
                'You took the criticism without flinching and gave her control of how she leaves. People remember the exit.',
            clarity: 2,
            empathy: 2,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'I’m sorry to hear that. Well — we’ll miss you.',
            scoreDelta: -6,
            feedback:
                'Polite, but she just handed you the most useful feedback of the year and you set it down.',
            clarity: -2,
            empathy: 0,
            directness: -2,
            confidence: -1,
          ),
          ResponseChoice(
            text:
                'That’s hard to hear. It’s been a brutal year for me too, honestly.',
            scoreDelta: -7,
            feedback:
                'The conversation was hers for about ninety seconds. Now she is looking after you.',
            clarity: -1,
            empathy: -2,
            directness: -1,
            confidence: -2,
          ),
        ],
      ),
    ],
  ),
];
