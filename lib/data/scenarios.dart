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
    difficulty: ScenarioDifficulty.challenging,
    icon: Icons.schedule_rounded,
    tint: AppColors.peach,
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
            courage: -2,
          ),
          ResponseChoice(
            text:
                'I see how much you’ve taken on. I also need us to address the two missed handoffs and their impact.',
            scoreDelta: 14,
            feedback:
                'Strong opening: you held empathy and accountability at the same time.',
            clarity: 2,
            empathy: 2,
            courage: 2,
          ),
          ResponseChoice(
            text:
                'Everyone is stretched. Missing deadlines at your level isn’t acceptable.',
            scoreDelta: -2,
            feedback:
                'The standard is clear, but the opening may make Jordan defensive.',
            clarity: 2,
            empathy: -2,
            courage: 1,
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
            courage: 1,
          ),
          ResponseChoice(
            text:
                'That sounds like an excuse. You still need to communicate sooner.',
            scoreDelta: -5,
            feedback:
                'There is a useful expectation here, but dismissing the concern shuts down candor.',
            clarity: 2,
            empathy: -2,
            courage: 1,
          ),
          ResponseChoice(
            text: 'Okay. I’ll speak to engineering and sort it out for you.',
            scoreDelta: -4,
            feedback:
                'You took ownership away from Jordan before clarifying what support is needed.',
            clarity: -1,
            empathy: 1,
            courage: -1,
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
            courage: 2,
          ),
          ResponseChoice(
            text: 'Just do your best and keep me posted.',
            scoreDelta: -8,
            feedback:
                'Supportive, but too vague to change the pattern you came to discuss.',
            clarity: -2,
            empathy: 1,
            courage: -2,
          ),
          ResponseChoice(
            text: 'Friday is the deadline. I expect you to figure it out.',
            scoreDelta: -3,
            feedback:
                'You held the line, but ignored a credible capacity constraint.',
            clarity: 2,
            empathy: -2,
            courage: 1,
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
    difficulty: ScenarioDifficulty.highStakes,
    icon: Icons.shield_outlined,
    tint: AppColors.lavender,
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
            courage: 2,
          ),
          ResponseChoice(
            text:
                'We’ll do our best. I’ll see what the team can pull together.',
            scoreDelta: -8,
            feedback:
                'This sounds agreeable, but it hides the delivery risk and overcommits the team.',
            clarity: -2,
            empathy: 1,
            courage: -2,
          ),
          ResponseChoice(
            text: 'No. That timeline is completely unrealistic.',
            scoreDelta: -2,
            feedback:
                'The boundary is unmistakable, but you have not helped Maya make a next decision.',
            clarity: 2,
            empathy: -2,
            courage: 2,
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
            courage: 2,
          ),
          ResponseChoice(
            text: 'Fine. I’ll tell the team they need to work late.',
            scoreDelta: -10,
            feedback:
                'You passed pressure downstream without testing scope or protecting the team.',
            clarity: 0,
            empathy: -2,
            courage: -2,
          ),
          ResponseChoice(
            text: 'Why was this announced before anyone checked with us?',
            scoreDelta: -4,
            feedback:
                'A fair process question, but it pulls focus away from the decision needed now.',
            clarity: -1,
            empathy: -1,
            courage: 1,
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
            courage: 2,
          ),
          ResponseChoice(
            text: 'Great, I’ll get something over to you soon.',
            scoreDelta: -5,
            feedback:
                'Positive, but “something” and “soon” leave the agreement exposed.',
            clarity: -2,
            empathy: 1,
            courage: -1,
          ),
          ResponseChoice(
            text: 'Okay, but I want it noted that this still isn’t realistic.',
            scoreDelta: -3,
            feedback:
                'You re-opened the conflict after finding a workable path.',
            clarity: 0,
            empathy: -1,
            courage: 0,
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
    difficulty: ScenarioDifficulty.warmUp,
    icon: Icons.handshake_outlined,
    tint: AppColors.mint,
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
            courage: 2,
          ),
          ResponseChoice(
            text:
                'I’m sorry, but you were also pretty aggressive in that meeting.',
            scoreDelta: -6,
            feedback:
                'The “but” turns the apology into a countercharge before repair has started.',
            clarity: 0,
            empathy: -2,
            courage: 0,
          ),
          ResponseChoice(
            text: 'I think we both got a little carried away.',
            scoreDelta: -4,
            feedback:
                'This lowers the temperature, but blurs your ownership of what happened.',
            clarity: -1,
            empathy: 1,
            courage: -1,
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
            courage: 2,
          ),
          ResponseChoice(
            text: 'That wasn’t my intention at all. You misunderstood me.',
            scoreDelta: -7,
            feedback:
                'Explaining intent too soon invalidates the impact Alex just shared.',
            clarity: 0,
            empathy: -2,
            courage: -1,
          ),
          ResponseChoice(
            text: 'I hear you.',
            scoreDelta: 0,
            feedback:
                'A calm acknowledgment, though it stops short of showing what you understood.',
            clarity: -1,
            empathy: 1,
            courage: 0,
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
            courage: 1,
          ),
          ResponseChoice(
            text: 'Absolutely. Let’s just start fresh next time.',
            scoreDelta: -3,
            feedback:
                'Warm, but there is no behavioral change to make “fresh” feel different.',
            clarity: -2,
            empathy: 1,
            courage: -1,
          ),
          ResponseChoice(
            text: 'Sure—as long as you keep the criticism constructive too.',
            scoreDelta: -2,
            feedback:
                'The request is valid, but the conditional framing makes the repair transactional.',
            clarity: 1,
            empathy: -1,
            courage: 1,
          ),
        ],
      ),
    ],
  ),
];
