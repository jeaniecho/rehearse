import 'package:flutter/material.dart';

import '../models/scenario.dart';
import '../models/session_outcome.dart';
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
            resolution: SessionOutcome.success,
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
            resolution: SessionOutcome.unresolved,
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
            resolution: SessionOutcome.escalated,
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
            resolution: SessionOutcome.success,
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
            resolution: SessionOutcome.unresolved,
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
            resolution: SessionOutcome.partial,
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
            resolution: SessionOutcome.success,
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
            resolution: SessionOutcome.partial,
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
            resolution: SessionOutcome.unresolved,
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
            resolution: SessionOutcome.success,
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
            resolution: SessionOutcome.unresolved,
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
            resolution: SessionOutcome.escalated,
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
            resolution: SessionOutcome.success,
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
            resolution: SessionOutcome.unresolved,
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
            resolution: SessionOutcome.partial,
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
            resolution: SessionOutcome.success,
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
            resolution: SessionOutcome.unresolved,
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
            resolution: SessionOutcome.escalated,
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
            resolution: SessionOutcome.success,
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
            resolution: SessionOutcome.unresolved,
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
            resolution: SessionOutcome.escalated,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'delegation',
    title: 'The work that keeps coming back',
    subtitle: 'Leave something hard in someone else’s hands.',
    skill: 'Delegation',
    durationMinutes: 4,
    stakes: ScenarioStakes.warmUp,
    icon: Icons.outbox_outlined,
    tint: AppColors.subtle,
    personName: 'Elif Demir',
    personRole: 'Data analyst',
    personInitials: 'ED',
    context:
        'Elif is presenting the quarterly business review on Thursday — the first exec-facing thing you have handed over. The slides are strong. Elif has now asked you twice to present it instead.',
    goal:
        'Leave the presentation with Elif, and agree on the support that makes that reasonable rather than reckless.',
    watchFor:
        'Taking the work back will feel like kindness. It is the one move that guarantees nothing changes.',
    openingLine:
        'The deck is basically done — I just think it lands better coming from you. You know that room.',
    turns: [
      DialogueTurn(
        employeeLine:
            'The deck is basically done — I just think it lands better coming from you. You know that room.',
        prompt: 'How do you answer?',
        choices: [
          ResponseChoice(
            text:
                'The deck is yours and so is the room. Tell me what would make Thursday feel survivable.',
            scoreDelta: 14,
            feedback:
                'You left ownership where it was and asked what support would make it work — that is the whole job.',
            clarity: 2,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'You’re probably right — I’ll present it and you can walk me through the slides beforehand.',
            scoreDelta: -8,
            feedback:
                'Kind, and the fastest way to teach Elif that hard things come back to you.',
            clarity: -1,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'You’ll be fine. It’s only a readout.',
            scoreDelta: -3,
            feedback:
                'You held the line, but waved away a worry you had not heard yet.',
            clarity: 0,
            empathy: -2,
            directness: 2,
            confidence: 1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Last time I presented, I got cut off four slides in and asked for numbers I didn’t have. I don’t want that in front of the whole leadership team.',
        prompt: 'Elif names the real fear. What next?',
        choices: [
          ResponseChoice(
            text:
                'That’s a fair thing to be worried about. Which question would you least want to be asked?',
            scoreDelta: 10,
            feedback:
                'You treated the fear as information and started rehearsing the actual risk.',
            clarity: 1,
            empathy: 2,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'That happens to everyone in there. Try not to take it personally.',
            scoreDelta: -5,
            feedback:
                'Normalising it is not the same as preparing for it, and it landed as dismissive.',
            clarity: 0,
            empathy: -1,
            directness: 0,
            confidence: 1,
          ),
          ResponseChoice(
            text: 'I’ll sit next to you and jump in if it gets rough.',
            scoreDelta: -4,
            feedback:
                'Sitting in as backup sounds supportive; it also tells the room who really owns this.',
            clarity: -1,
            empathy: 2,
            directness: -2,
            confidence: -1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Okay. If I can get the regional numbers from finance by Tuesday, I think I can hold my own.',
        prompt: 'Close it.',
        choices: [
          ResponseChoice(
            text:
                'Then Tuesday is the checkpoint. Send me the two slides you are least sure of and I’ll push on them, not fix them.',
            scoreDelta: 14,
            feedback:
                'A checkpoint with a stated limit — you offered pressure-testing rather than rescue.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
            resolution: SessionOutcome.success,
          ),
          ResponseChoice(
            text:
                'Great. And if finance is slow, just send it over and I’ll finish it off.',
            scoreDelta: -8,
            feedback:
                'One sentence undid the handover: the exit you left is the one Elif will take.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
            resolution: SessionOutcome.unresolved,
          ),
          ResponseChoice(
            text: 'Good. Thursday, ten o’clock, you’re presenting.',
            scoreDelta: -2,
            feedback:
                'Unambiguous, but you closed without agreeing the one thing Elif said they needed.',
            clarity: 2,
            empathy: -2,
            directness: 2,
            confidence: 1,
            resolution: SessionOutcome.partial,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'after-hours',
    title: 'The midnight messages',
    subtitle:
        'Set an expectation about time off without asking someone to care less.',
    skill: 'Protecting time',
    durationMinutes: 3,
    stakes: ScenarioStakes.challenging,
    icon: Icons.bedtime_outlined,
    tint: AppColors.subtle,
    personName: 'Tomás Ferreira',
    personRole: 'Support lead',
    personInitials: 'TF',
    context:
        'Tomás posts to the team channel at all hours and follows up when nobody answers. Two people have started replying at 1am. Tomás is also the most responsive person you have, and knows it.',
    goal:
        'Set a clear expectation about response times outside working hours, and keep the urgency you actually want.',
    watchFor:
        'You have answered plenty of those midnight messages yourself. Tomás learned this somewhere.',
    openingLine:
        'Is this about last night? I only pinged the channel because the queue was backing up and I didn’t want it landing on you in the morning.',
    turns: [
      DialogueTurn(
        employeeLine:
            'Is this about last night? I only pinged the channel because the queue was backing up and I didn’t want it landing on you in the morning.',
        prompt: 'How do you answer?',
        choices: [
          ResponseChoice(
            text:
                'I believe that, and it still has to change. Nothing in that channel needs an answer before nine unless you page someone.',
            scoreDelta: 12,
            feedback:
                'You accepted the good intent and set the expectation anyway — the two are not in competition.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'It’s fine — I’d rather you over-communicate than sit on something.',
            scoreDelta: -6,
            feedback:
                'You called the thing you came to fix a preference. Nothing about tonight will be different.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -1,
          ),
          ResponseChoice(
            text:
                'People are answering you at one in the morning. That is not okay.',
            scoreDelta: -3,
            feedback:
                'The problem is real, but you made Tomás the culprit for caring, and the expectation still went unsaid.',
            clarity: 1,
            empathy: -2,
            directness: 2,
            confidence: 0,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'So I should let it sit? You answer me at midnight all the time. I assumed that was the job.',
        prompt: 'Tomás has a point. What next?',
        choices: [
          ResponseChoice(
            text:
                'That’s fair, and it’s on me. I have been modelling something I don’t actually want from you.',
            scoreDelta: 10,
            feedback:
                'Owning it cost you nothing and bought you the only version of this rule anyone will follow.',
            clarity: 1,
            empathy: 2,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'That’s different — I’m the manager. My hours are my problem.',
            scoreDelta: -5,
            feedback:
                'A rule that exempts the person setting it is not a rule, and Tomás heard exactly that.',
            clarity: 0,
            empathy: -2,
            directness: 1,
            confidence: -1,
          ),
          ResponseChoice(
            text: 'Let’s not make this about me. The point is the channel.',
            scoreDelta: -4,
            feedback:
                'You ducked a fair observation, which reads as less certain than saying nothing would have.',
            clarity: 0,
            empathy: -1,
            directness: 1,
            confidence: -2,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Okay. But if something actually breaks at 2am, I’m not going to sit there watching it.',
        prompt: 'Close it.',
        choices: [
          ResponseChoice(
            text:
                'Right — that’s what the pager is for. Page whoever is on call and leave the channel until morning.',
            scoreDelta: 14,
            feedback:
                'You named the one exception and the route it takes, so the boundary survives its first hard night.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
            resolution: SessionOutcome.success,
          ),
          ResponseChoice(
            text:
                'Use your judgement. If it feels urgent, put it in the channel and someone will pick it up.',
            scoreDelta: -8,
            feedback:
                '“Use your judgement” handed the boundary straight back to the person whose judgement brought you here.',
            clarity: -2,
            empathy: 0,
            directness: -2,
            confidence: -1,
            resolution: SessionOutcome.unresolved,
          ),
          ResponseChoice(
            text: 'Then page me directly, and nobody else.',
            scoreDelta: -2,
            feedback:
                'You protected the team by making yourself the exception. That holds until the week you are unreachable.',
            clarity: 1,
            empathy: 1,
            directness: 1,
            confidence: -2,
            resolution: SessionOutcome.partial,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'below-bar',
    title: 'The work that isn’t at the level',
    subtitle:
        'Say that the work is below the bar, after months of saying it was nearly there.',
    skill: 'Straight talk',
    durationMinutes: 4,
    stakes: ScenarioStakes.highStakes,
    icon: Icons.fact_check_outlined,
    tint: AppColors.subtle,
    personName: 'Marta Nowak',
    personRole: 'Content strategist',
    personInitials: 'MN',
    context:
        'Marta is eight months into the role. Three of the last four briefs came back needing a rewrite you did yourself, and you called each one “nearly there”. Marta believes this is going well.',
    goal:
        'Say plainly that the work is not yet at the level the role needs, and describe what being at the level would look like.',
    watchFor:
        'You have called this work nearly there three times. Whatever you say now contradicts you, and Marta will hear that first.',
    openingLine:
        'Before we start — thanks for the note on the Q3 brief. Good to know it landed. I feel like I’m finally getting the hang of these.',
    turns: [
      DialogueTurn(
        employeeLine:
            'Before we start — thanks for the note on the Q3 brief. Good to know it landed. I feel like I’m finally getting the hang of these.',
        prompt: 'How do you open?',
        choices: [
          ResponseChoice(
            text:
                'That’s the thing I need to correct today. I rewrote most of that brief before it went out, and I should have told you at the time.',
            scoreDelta: 12,
            feedback:
                'You corrected the record in the first sentence, which is the only place it could have gone without becoming a bigger lie.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'You are getting the hang of them. There are just a few things I wanted to touch on.',
            scoreDelta: -6,
            feedback:
                'That is the fourth time you have softened it. Marta now has four reasons to disbelieve the fifth.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text: 'Honestly, none of the last four briefs were usable.',
            scoreDelta: -4,
            feedback:
                'True, and delivered as eight months of withheld feedback in one sentence.',
            clarity: 1,
            empathy: -2,
            directness: 2,
            confidence: 1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'You rewrote it? You told me it was nearly there. If it was that bad, why has nobody said anything for eight months?',
        prompt: 'The fair question. Answer it.',
        choices: [
          ResponseChoice(
            text:
                'Because I kept softening it, and that is on me. Let me show you the brief you sent next to the one that went out.',
            scoreDelta: 10,
            feedback:
                'You answered the question and then made the bar something Marta can see rather than something you assert.',
            clarity: 2,
            empathy: 1,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'I didn’t want to knock your confidence while you were still settling in.',
            scoreDelta: -5,
            feedback:
                'Kindly meant, and it cost Marta eight months in which the work could have improved.',
            clarity: -1,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
          ResponseChoice(
            text:
                'Let’s focus forward rather than relitigating the last eight months.',
            scoreDelta: -4,
            feedback:
                'You skipped past the one question Marta is entitled to an answer to, and it will be back.',
            clarity: -1,
            empathy: -1,
            directness: 0,
            confidence: -1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine: 'Okay. So am I on some kind of warning here, or not?',
        prompt: 'Be plain.',
        choices: [
          ResponseChoice(
            text:
                'Not yet, and I am not going to pretend it isn’t on the table. Two briefs by the end of the month with no rewrites from me — then we both know where we stand.',
            scoreDelta: 14,
            feedback:
                'You told the truth about the stakes and gave it a shape Marta can actually pass or fail.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
            resolution: SessionOutcome.success,
          ),
          ResponseChoice(
            text:
                'No, nothing like that. Let’s keep talking and see how it goes.',
            scoreDelta: -8,
            feedback:
                'You spent the whole conversation getting to the truth and then took it back in the last line.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
            resolution: SessionOutcome.unresolved,
          ),
          ResponseChoice(
            text: 'Not a warning. But I need to see a real change, and soon.',
            scoreDelta: -2,
            feedback:
                '“Real change, soon” is not something anyone can act on, and Marta will read it as whatever is least alarming.',
            clarity: 0,
            empathy: 1,
            directness: 1,
            confidence: 0,
            resolution: SessionOutcome.partial,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'disagree-commit',
    title: 'The decision that won’t stay closed',
    subtitle:
        'Close a decision without shutting down the person who disagreed.',
    skill: 'Alignment',
    durationMinutes: 4,
    stakes: ScenarioStakes.challenging,
    icon: Icons.replay_rounded,
    tint: AppColors.subtle,
    personName: 'Daniel Kowalski',
    personRole: 'Staff engineer',
    personInitials: 'DK',
    context:
        'The team agreed six weeks ago to consolidate on one deployment pipeline. Daniel argued against it, lost, and has raised it again in three of the last four team meetings. Daniel may also be right.',
    goal:
        'Close the decision for now, and give the objection a legitimate route that is not the team meeting.',
    watchFor:
        'Winning this by authority costs you the one person who tells you when you are wrong.',
    openingLine:
        'I know you think this is settled. I just don’t think we ever answered the rollback question, and I’m not going to pretend I’m comfortable with it.',
    turns: [
      DialogueTurn(
        employeeLine:
            'I know you think this is settled. I just don’t think we ever answered the rollback question, and I’m not going to pretend I’m comfortable with it.',
        prompt: 'How do you answer?',
        choices: [
          ResponseChoice(
            text:
                'You’re right that we never answered it. The decision still stands, and the rollback gap is a real thing I want written down.',
            scoreDelta: 12,
            feedback:
                'You separated the objection from the decision, so you could hold one and take the other seriously.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'We decided this. I need you to get behind it and stop bringing it up.',
            scoreDelta: -6,
            feedback:
                'Authority closed the meeting and taught your most careful engineer to stop flagging risk out loud.',
            clarity: 1,
            empathy: -2,
            directness: 2,
            confidence: -1,
          ),
          ResponseChoice(
            text:
                'Maybe we should put it back on the agenda and look at it properly.',
            scoreDelta: -4,
            feedback:
                'Reopening it on the fourth ask teaches the team that decisions last until someone is persistent enough.',
            clarity: -2,
            empathy: 1,
            directness: -2,
            confidence: -2,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'So it stands even though the concern is real. That’s the part I don’t understand.',
        prompt: 'Explain the difference.',
        choices: [
          ResponseChoice(
            text:
                'Because being right about the risk and being right about the timing are not the same thing. Own the rollback plan and I will back it in the next review.',
            scoreDelta: 10,
            feedback:
                'You gave the objection somewhere real to go, which is what makes “the decision stands” something other than a brush-off.',
            clarity: 2,
            empathy: 1,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text:
                'Honestly, I don’t have the energy to reopen this. Can you let it go?',
            scoreDelta: -5,
            feedback:
                'You made your own fatigue the reason, which is the one justification nobody can respect.',
            clarity: 0,
            empathy: 0,
            directness: -1,
            confidence: -2,
          ),
          ResponseChoice(
            text:
                'The concern isn’t that real. The pipeline has rolled back fine twice already.',
            scoreDelta: -3,
            feedback:
                'You argued the technical point down instead of closing the decision, and now you are losing on both.',
            clarity: 1,
            empathy: -1,
            directness: 1,
            confidence: 1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Fine. I’ll write it up. But if this bites us in November, I want it on record that I said so.',
        prompt: 'Close it.',
        choices: [
          ResponseChoice(
            text:
                'Put it in the doc with your name on it. If it bites us, I want the record to say you called it.',
            scoreDelta: 14,
            feedback:
                'You made dissent a thing that gets credited rather than tolerated, which is how you keep hearing it.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
            resolution: SessionOutcome.success,
          ),
          ResponseChoice(
            text:
                'Let’s not do the on-record thing. If it goes wrong we’ll deal with it then.',
            scoreDelta: -8,
            feedback:
                'You refused the one thing Daniel asked for, and it was the cheapest thing in the conversation.',
            clarity: -2,
            empathy: -1,
            directness: -2,
            confidence: -2,
            resolution: SessionOutcome.escalated,
          ),
          ResponseChoice(
            text: 'Noted. Send it over when it’s done.',
            scoreDelta: -2,
            feedback:
                'Daniel was asking to be trusted, and you answered the logistics.',
            clarity: 1,
            empathy: -1,
            directness: 1,
            confidence: 0,
            resolution: SessionOutcome.partial,
          ),
        ],
      ),
    ],
  ),
  Scenario(
    id: 'overloaded',
    title: 'The person who never says no',
    subtitle: 'Take work off someone without taking their standing with it.',
    skill: 'Workload',
    durationMinutes: 3,
    stakes: ScenarioStakes.warmUp,
    icon: Icons.layers_outlined,
    tint: AppColors.subtle,
    personName: 'Hana Sato',
    personRole: 'Implementation consultant',
    personInitials: 'HS',
    context:
        'Hana has said yes to four things this month, two of which were not Hana’s to take. The work is still good. Last week Hana apologised for a slow reply at 7am on a Sunday.',
    goal:
        'Take two things off Hana’s plate, and make it unmistakable that this is about load rather than performance.',
    watchFor:
        'Hana will hear “let me take that back” as “you couldn’t handle it”. Say which one you mean.',
    openingLine:
        'I’m fine, honestly. The migration is the only heavy one and it’s nearly done. I’d rather be busy than bored.',
    turns: [
      DialogueTurn(
        employeeLine:
            'I’m fine, honestly. The migration is the only heavy one and it’s nearly done. I’d rather be busy than bored.',
        prompt: 'How do you answer?',
        choices: [
          ResponseChoice(
            text:
                'I believe you could carry all of it. I’m not willing to find out what it costs you.',
            scoreDelta: 12,
            feedback:
                'You did not argue about whether Hana is coping — you made the decision yours, which is where it belongs.',
            clarity: 1,
            empathy: 2,
            directness: 2,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Okay — shout if it gets to be too much.',
            scoreDelta: -6,
            feedback:
                'You asked the person who never says no to say no. Nothing changes.',
            clarity: -2,
            empathy: 0,
            directness: -2,
            confidence: -1,
          ),
          ResponseChoice(
            text:
                'You’re not fine. You apologised for a slow reply at 7am on a Sunday.',
            scoreDelta: -3,
            feedback:
                'The observation is the right one, delivered as evidence in a case against Hana.',
            clarity: 2,
            empathy: -1,
            directness: 2,
            confidence: 1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'If you take the migration off me, what does that say to everyone else? I asked for that one.',
        prompt: 'Hana is asking about status, not workload.',
        choices: [
          ResponseChoice(
            text:
                'It says I gave you the migration and then put three more things on top of it. That’s my error to fix, not yours to absorb.',
            scoreDelta: 10,
            feedback:
                'You put the story on your own decision-making, which is the only version that does not cost Hana standing.',
            clarity: 2,
            empathy: 2,
            directness: 1,
            confidence: 2,
          ),
          ResponseChoice(
            text: 'Nobody is going to read anything into it.',
            scoreDelta: -5,
            feedback:
                'You told someone their worry was imaginary. They will keep it and stop mentioning it.',
            clarity: -1,
            empathy: -2,
            directness: 0,
            confidence: 0,
          ),
          ResponseChoice(
            text:
                'Let’s not overthink the optics. I’m reassigning it either way.',
            scoreDelta: -4,
            feedback:
                'You got the decision right and spent all its goodwill dismissing a legitimate question.',
            clarity: 1,
            empathy: -2,
            directness: 2,
            confidence: 1,
          ),
        ],
      ),
      DialogueTurn(
        employeeLine:
            'Okay. But I don’t want this to be the thing that comes up when we talk about promotion.',
        prompt: 'Close it.',
        choices: [
          ResponseChoice(
            text:
                'It won’t, because this isn’t a performance conversation. What will come up is whether you can tell me you’re at capacity before I have to notice.',
            scoreDelta: 14,
            feedback:
                'You closed the fear and named the actual skill you want, so the load conversation became a development one.',
            clarity: 2,
            empathy: 1,
            directness: 2,
            confidence: 2,
            resolution: SessionOutcome.success,
          ),
          ResponseChoice(
            text:
                'Let’s worry about promotion later. Right now just get the migration handed over.',
            scoreDelta: -8,
            feedback:
                'Hana raised the thing they were most afraid of and you moved it to the bottom of the agenda.',
            clarity: 0,
            empathy: -2,
            directness: 1,
            confidence: -2,
            resolution: SessionOutcome.escalated,
          ),
          ResponseChoice(
            text: 'Of course not. This is a good thing, I promise.',
            scoreDelta: -2,
            feedback:
                'A promise with nothing behind it. Hana will believe the four items on the plate over the reassurance.',
            clarity: -1,
            empathy: 1,
            directness: -1,
            confidence: -1,
            resolution: SessionOutcome.partial,
          ),
        ],
      ),
    ],
  ),
];
