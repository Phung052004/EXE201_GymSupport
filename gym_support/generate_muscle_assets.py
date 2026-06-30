#!/usr/bin/env python3
"""Generate anatomical muscle SVG assets for GymSupport app."""

import os
from pathlib import Path

ASSETS_DIR = Path("assets/body/masks")
ASSETS_DIR.mkdir(parents=True, exist_ok=True)

# SVG template with gradients
SVG_TEMPLATE = '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="{id}_grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ffffff;stop-opacity:0.25" />
      <stop offset="100%" style="stop-color:#000000;stop-opacity:0.2" />
    </linearGradient>
    <linearGradient id="{id}_grad2" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#ffffff;stop-opacity:0.3" />
      <stop offset="100%" style="stop-color:#000000;stop-opacity:0.15" />
    </linearGradient>
  </defs>
  {content}
</svg>'''

MUSCLES = {
    # Front muscles
    "front_chest": {
        "content": '''  <!-- Left pectoral -->
  <path d="M 100 40 Q 75 50 70 75 Q 68 100 75 120 Q 90 125 100 115 L 100 40" fill="currentColor" opacity="0.85"/>
  <!-- Right pectoral -->
  <path d="M 100 40 Q 125 50 130 75 Q 132 100 125 120 Q 110 125 100 115 L 100 40" fill="currentColor" opacity="0.85"/>
  <!-- Highlight -->
  <ellipse cx="85" cy="75" rx="12" ry="25" fill="url(#front_chest_grad1)" opacity="0.4"/>
  <ellipse cx="115" cy="75" rx="12" ry="25" fill="url(#front_chest_grad1)" opacity="0.4"/>
  <!-- Center line -->
  <line x1="100" y1="45" x2="100" y2="115" stroke="currentColor" stroke-width="1" opacity="0.25"/>'''
    },

    "front_biceps": {
        "content": '''  <!-- Bicep peak -->
  <path d="M 75 60 Q 65 80 68 110 Q 75 125 85 120 Q 90 100 90 70 Q 85 55 75 60" fill="currentColor" opacity="0.85"/>
  <!-- Inner highlight -->
  <path d="M 78 70 Q 72 85 74 110 Q 78 118 82 115 Q 85 95 85 75 Q 82 65 78 70" fill="url(#front_biceps_grad2)" opacity="0.35"/>
  <!-- Peak definition -->
  <ellipse cx="80" cy="75" rx="8" ry="15" fill="currentColor" opacity="0.3"/>'''
    },

    "front_triceps": {
        "content": '''  <!-- Tricep mass -->
  <path d="M 115 70 Q 135 80 138 110 Q 135 125 120 120 Q 115 100 115 70" fill="currentColor" opacity="0.85"/>
  <!-- Highlight streaks -->
  <path d="M 118 80 Q 130 90 132 110 Q 130 118 122 115 Q 118 100 118 80" fill="url(#front_triceps_grad1)" opacity="0.3"/>
  <!-- Definition -->
  <line x1="118" y1="75" x2="130" y2="110" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>'''
    },

    "front_shoulders_anterior": {
        "content": '''  <!-- Front delt bulge -->
  <ellipse cx="65" cy="45" rx="15" ry="22" fill="currentColor" opacity="0.85"/>
  <ellipse cx="135" cy="45" rx="15" ry="22" fill="currentColor" opacity="0.85"/>
  <!-- Highlights -->
  <ellipse cx="65" cy="40" rx="8" ry="12" fill="url(#front_shoulders_anterior_grad1)" opacity="0.4"/>
  <ellipse cx="135" cy="40" rx="8" ry="12" fill="url(#front_shoulders_anterior_grad1)" opacity="0.4"/>'''
    },

    "front_shoulders_lateral": {
        "content": '''  <!-- Side delt roundness -->
  <path d="M 60 50 Q 55 65 58 85 Q 68 92 75 80 Q 75 65 70 50 Q 65 48 60 50" fill="currentColor" opacity="0.85"/>
  <path d="M 140 50 Q 145 65 142 85 Q 132 92 125 80 Q 125 65 130 50 Q 135 48 140 50" fill="currentColor" opacity="0.85"/>
  <!-- Surface shine -->
  <ellipse cx="62" cy="60" rx="7" ry="12" fill="url(#front_shoulders_lateral_grad2)" opacity="0.35"/>
  <ellipse cx="138" cy="60" rx="7" ry="12" fill="url(#front_shoulders_lateral_grad2)" opacity="0.35"/>'''
    },

    "front_abs": {
        "content": '''  <!-- 6-pack grid -->
  <g opacity="0.85">
    <rect x="75" y="90" width="23" height="18" rx="2" fill="currentColor"/>
    <rect x="102" y="90" width="23" height="18" rx="2" fill="currentColor"/>
    <rect x="75" y="115" width="23" height="18" rx="2" fill="currentColor"/>
    <rect x="102" y="115" width="23" height="18" rx="2" fill="currentColor"/>
    <rect x="75" y="140" width="23" height="20" rx="2" fill="currentColor"/>
    <rect x="102" y="140" width="23" height="20" rx="2" fill="currentColor"/>
  </g>
  <!-- Ridge definition -->
  <line x1="100" y1="90" x2="100" y2="160" stroke="currentColor" stroke-width="1.2" opacity="0.3"/>
  <line x1="75" y1="108" x2="125" y2="108" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <line x1="75" y1="133" x2="125" y2="133" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <!-- Highlight -->
  <ellipse cx="100" cy="110" rx="20" ry="35" fill="url(#front_abs_grad2)" opacity="0.3"/>'''
    },

    "front_quads": {
        "content": '''  <!-- Vastus medialis (inner quad) -->
  <path d="M 85 140 Q 78 155 80 180 Q 90 185 100 180 L 100 140 Z" fill="currentColor" opacity="0.85"/>
  <!-- Vastus lateralis (outer quad) -->
  <path d="M 100 140 Q 122 155 120 180 Q 110 185 100 180 L 100 140 Z" fill="currentColor" opacity="0.85"/>
  <!-- Rectus femoris (center ridge) -->
  <rect x="90" y="140" width="20" height="40" rx="3" fill="currentColor" opacity="0.9"/>
  <!-- Vastus intermedius (inner layer) -->
  <ellipse cx="100" cy="160" rx="15" ry="20" fill="url(#front_quads_grad2)" opacity="0.35"/>'''
    },

    "front_calves": {
        "content": '''  <!-- Gastrocnemius bulge -->
  <path d="M 80 165 Q 72 175 72 190 Q 80 195 90 192 L 85 165 Z" fill="currentColor" opacity="0.85"/>
  <path d="M 120 165 Q 128 175 128 190 Q 120 195 110 192 L 115 165 Z" fill="currentColor" opacity="0.85"/>
  <!-- Soleus peek -->
  <ellipse cx="85" cy="180" rx="8" ry="10" fill="currentColor" opacity="0.7"/>
  <ellipse cx="115" cy="180" rx="8" ry="10" fill="currentColor" opacity="0.7"/>
  <!-- Highlight -->
  <path d="M 82 170 Q 76 178 76 188 Q 82 192 88 190" fill="url(#front_calves_grad1)" opacity="0.3"/>
  <path d="M 118 170 Q 124 178 124 188 Q 118 192 112 190" fill="url(#front_calves_grad1)" opacity="0.3"/>'''
    },

    "front_forearms": {
        "content": '''  <!-- Flexor mass -->
  <path d="M 70 120 Q 60 135 62 155 Q 72 160 78 150 L 75 120 Z" fill="currentColor" opacity="0.85"/>
  <!-- Extensor mass -->
  <path d="M 130 120 Q 140 135 138 155 Q 128 160 122 150 L 125 120 Z" fill="currentColor" opacity="0.85"/>
  <!-- Forearm ridge -->
  <line x1="75" y1="120" x2="72" y2="155" stroke="currentColor" stroke-width="1" opacity="0.25"/>
  <line x1="125" y1="120" x2="128" y2="155" stroke="currentColor" stroke-width="1" opacity="0.25"/>
  <!-- Highlight -->
  <ellipse cx="73" cy="140" rx="5" ry="12" fill="url(#front_forearms_grad1)" opacity="0.3"/>
  <ellipse cx="127" cy="140" rx="5" ry="12" fill="url(#front_forearms_grad1)" opacity="0.3"/>'''
    },

    "front_adductors": {
        "content": '''  <!-- Inner thigh adductors -->
  <path d="M 95 145 Q 85 160 86 180 Q 100 185 105 175 L 100 145 Z" fill="currentColor" opacity="0.85"/>
  <!-- Second adductor -->
  <path d="M 100 145 Q 110 160 115 180 Q 105 185 100 175 L 100 145 Z" fill="currentColor" opacity="0.8"/>
  <!-- Muscle definition -->
  <line x1="97" y1="145" x2="94" y2="180" stroke="currentColor" stroke-width="0.8" opacity="0.25"/>
  <line x1="103" y1="145" x2="108" y2="180" stroke="currentColor" stroke-width="0.8" opacity="0.25"/>
  <!-- Highlight inner contour -->
  <path d="M 98 155 Q 92 168 93 178" stroke="url(#front_adductors_grad1)" stroke-width="2" fill="none" opacity="0.3"/>'''
    },

    "front_core": {
        "content": '''  <!-- Deep core visualization -->
  <ellipse cx="100" cy="110" rx="22" ry="35" fill="currentColor" opacity="0.8"/>
  <!-- Inner depth -->
  <ellipse cx="100" cy="110" rx="16" ry="28" fill="currentColor" opacity="0.6"/>
  <!-- Highlight center -->
  <ellipse cx="100" cy="100" rx="12" ry="20" fill="url(#front_core_grad2)" opacity="0.35"/>
  <!-- Transverse lines -->
  <line x1="80" y1="95" x2="120" y2="95" stroke="currentColor" stroke-width="0.6" opacity="0.15"/>
  <line x1="78" y1="110" x2="122" y2="110" stroke="currentColor" stroke-width="0.6" opacity="0.15"/>
  <line x1="80" y1="125" x2="120" y2="125" stroke="currentColor" stroke-width="0.6" opacity="0.15"/>'''
    },

    "front_obliques": {
        "content": '''  <!-- Right obliques -->
  <path d="M 110 95 Q 130 110 128 140 Q 120 145 110 135 L 110 95" fill="currentColor" opacity="0.85"/>
  <!-- Left obliques -->
  <path d="M 90 95 Q 70 110 72 140 Q 80 145 90 135 L 90 95" fill="currentColor" opacity="0.85"/>
  <!-- Diagonal fiber lines -->
  <line x1="115" y1="100" x2="125" y2="135" stroke="currentColor" stroke-width="0.7" opacity="0.2"/>
  <line x1="105" y1="100" x2="120" y2="140" stroke="currentColor" stroke-width="0.7" opacity="0.15"/>
  <!-- Left diagonal -->
  <line x1="85" y1="100" x2="75" y2="135" stroke="currentColor" stroke-width="0.7" opacity="0.2"/>
  <line x1="95" y1="100" x2="80" y2="140" stroke="currentColor" stroke-width="0.7" opacity="0.15"/>
  <!-- Highlight shine -->
  <ellipse cx="120" cy="115" rx="8" ry="18" fill="url(#front_obliques_grad1)" opacity="0.25"/>
  <ellipse cx="80" cy="115" rx="8" ry="18" fill="url(#front_obliques_grad1)" opacity="0.25"/>'''
    },

    # Back muscles
    "back_lats": {
        "content": '''  <!-- Large wing-like lats -->
  <path d="M 100 50 Q 70 65 60 95 Q 55 120 65 140 Q 85 145 100 125 L 100 50" fill="currentColor" opacity="0.85"/>
  <path d="M 100 50 Q 130 65 140 95 Q 145 120 135 140 Q 115 145 100 125 L 100 50" fill="currentColor" opacity="0.85"/>
  <!-- Lat striation -->
  <path d="M 85 70 Q 70 85 62 110 Q 60 125 68 138" stroke="currentColor" stroke-width="1" fill="none" opacity="0.2"/>
  <path d="M 115 70 Q 130 85 138 110 Q 140 125 132 138" stroke="currentColor" stroke-width="1" fill="none" opacity="0.2"/>
  <!-- Highlight wing edge -->
  <ellipse cx="70" cy="95" rx="12" ry="30" fill="url(#back_lats_grad2)" opacity="0.3"/>
  <ellipse cx="130" cy="95" rx="12" ry="30" fill="url(#back_lats_grad2)" opacity="0.3"/>'''
    },

    "back_traps": {
        "content": '''  <!-- Upper trapezius -->
  <path d="M 100 30 Q 75 40 70 60 Q 75 65 90 58 Q 100 45 100 30" fill="currentColor" opacity="0.85"/>
  <path d="M 100 30 Q 125 40 130 60 Q 125 65 110 58 Q 100 45 100 30" fill="currentColor" opacity="0.85"/>
  <!-- Mid traps -->
  <path d="M 75 60 Q 65 75 68 90 Q 80 95 90 85 L 85 65 Z" fill="currentColor" opacity="0.8"/>
  <path d="M 125 60 Q 135 75 132 90 Q 120 95 110 85 L 115 65 Z" fill="currentColor" opacity="0.8"/>
  <!-- Trap definition lines -->
  <line x1="100" y1="35" x2="85" y2="85" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <line x1="100" y1="35" x2="115" y2="85" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <!-- Highlight sheen -->
  <ellipse cx="82" cy="55" rx="8" ry="15" fill="url(#back_traps_grad1)" opacity="0.35"/>
  <ellipse cx="118" cy="55" rx="8" ry="15" fill="url(#back_traps_grad1)" opacity="0.35"/>'''
    },

    "back_triceps": {
        "content": '''  <!-- Tricep horseshoe -->
  <path d="M 75 70 Q 65 90 68 120 Q 80 128 85 115 L 80 75 Z" fill="currentColor" opacity="0.85"/>
  <path d="M 125 70 Q 135 90 132 120 Q 120 128 115 115 L 120 75 Z" fill="currentColor" opacity="0.85"/>
  <!-- Long head definition -->
  <path d="M 100 80 Q 95 100 97 120 Q 105 125 108 115 L 102 85 Z" fill="currentColor" opacity="0.75"/>
  <!-- Tricep striations -->
  <line x1="78" y1="80" x2="72" y2="115" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <line x1="122" y1="80" x2="128" y2="115" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <!-- Highlight center -->
  <ellipse cx="100" cy="100" rx="8" ry="20" fill="url(#back_triceps_grad2)" opacity="0.3"/>'''
    },

    "back_shoulders_posterior": {
        "content": '''  <!-- Rear delt rounded -->
  <ellipse cx="65" cy="55" rx="16" ry="24" fill="currentColor" opacity="0.85"/>
  <ellipse cx="135" cy="55" rx="16" ry="24" fill="currentColor" opacity="0.85"/>
  <!-- Delt separation from trap -->
  <line x1="62" y1="45" x2="65" y2="75" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <line x1="138" y1="45" x2="135" y2="75" stroke="currentColor" stroke-width="0.8" opacity="0.2"/>
  <!-- Rear delt shine -->
  <ellipse cx="63" cy="50" rx="9" ry="14" fill="url(#back_shoulders_posterior_grad1)" opacity="0.35"/>
  <ellipse cx="137" cy="50" rx="9" ry="14" fill="url(#back_shoulders_posterior_grad1)" opacity="0.35"/>
  <!-- Subtle roundness lines -->
  <path d="M 55 60 Q 60 65 65 65" stroke="currentColor" stroke-width="0.6" fill="none" opacity="0.15"/>
  <path d="M 145 60 Q 140 65 135 65" stroke="currentColor" stroke-width="0.6" fill="none" opacity="0.15"/>'''
    },

    "back_rhomboids": {
        "content": '''  <!-- Rhomboid diamond shape -->
  <path d="M 100 45 L 85 65 L 100 85 L 115 65 Z" fill="currentColor" opacity="0.85"/>
  <!-- Inner shading -->
  <path d="M 100 55 L 90 65 L 100 75 L 110 65 Z" fill="currentColor" opacity="0.6"/>
  <!-- Edge definition -->
  <line x1="100" y1="45" x2="85" y2="65" stroke="currentColor" stroke-width="0.8" opacity="0.25"/>
  <line x1="85" y1="65" x2="100" y2="85" stroke="currentColor" stroke-width="0.8" opacity="0.25"/>
  <line x1="100" y1="85" x2="115" y2="65" stroke="currentColor" stroke-width="0.8" opacity="0.25"/>
  <line x1="115" y1="65" x2="100" y2="45" stroke="currentColor" stroke-width="0.8" opacity="0.25"/>
  <!-- Highlight -->
  <ellipse cx="102" cy="60" rx="6" ry="10" fill="url(#back_rhomboids_grad1)" opacity="0.35"/>'''
    },

    "back_teres_major": {
        "content": '''  <!-- Round muscle below lat -->
  <ellipse cx="75" cy="110" rx="14" ry="20" fill="currentColor" opacity="0.85"/>
  <ellipse cx="125" cy="110" rx="14" ry="20" fill="currentColor" opacity="0.85"/>
  <!-- Inner curve definition -->
  <ellipse cx="75" cy="110" rx="10" ry="15" fill="currentColor" opacity="0.65"/>
  <ellipse cx="125" cy="110" rx="10" ry="15" fill="currentColor" opacity="0.65"/>
  <!-- Roundness shine -->
  <ellipse cx="72" cy="105" rx="6" ry="10" fill="url(#back_teres_major_grad1)" opacity="0.3"/>
  <ellipse cx="128" cy="105" rx="6" ry="10" fill="url(#back_teres_major_grad1)" opacity="0.3"/>'''
    },

    "back_hamstrings": {
        "content": '''  <!-- Biceps femoris (outer) -->
  <path d="M 85 150 Q 75 165 76 190 Q 85 195 95 190 L 90 150 Z" fill="currentColor" opacity="0.85"/>
  <!-- Semitendinosus (inner) -->
  <path d="M 100 150 Q 115 165 114 190 Q 105 195 95 190 L 100 150 Z" fill="currentColor" opacity="0.85"/>
  <!-- Semimembranosus (under) -->
  <path d="M 92 155 Q 98 170 100 190 Q 96 195 90 193 L 92 155 Z" fill="currentColor" opacity="0.75"/>
  <!-- Muscle striations -->
  <line x1="88" y1="155" x2="80" y2="190" stroke="currentColor" stroke-width="0.7" opacity="0.15"/>
  <line x1="108" y1="155" x2="115" y2="190" stroke="currentColor" stroke-width="0.7" opacity="0.15"/>
  <!-- Highlight -->
  <ellipse cx="92" cy="170" rx="6" ry="15" fill="url(#back_hamstrings_grad2)" opacity="0.3"/>
  <ellipse cx="108" cy="170" rx="6" ry="15" fill="url(#back_hamstrings_grad2)" opacity="0.3"/>'''
    },

    "back_glute": {
        "content": '''  <!-- Gluteus maximus broad shape -->
  <ellipse cx="80" cy="135" rx="18" ry="28" fill="currentColor" opacity="0.85"/>
  <ellipse cx="120" cy="135" rx="18" ry="28" fill="currentColor" opacity="0.85"/>
  <!-- Gluteus medius on top -->
  <ellipse cx="80" cy="115" rx="14" ry="18" fill="currentColor" opacity="0.8"/>
  <ellipse cx="120" cy="115" rx="14" ry="18" fill="currentColor" opacity="0.8"/>
  <!-- Center cleft definition -->
  <line x1="100" y1="110" x2="100" y2="160" stroke="currentColor" stroke-width="1.2" opacity="0.25"/>
  <!-- Curvature highlights -->
  <ellipse cx="75" cy="130" rx="8" ry="18" fill="url(#back_glute_grad2)" opacity="0.3"/>
  <ellipse cx="125" cy="130" rx="8" ry="18" fill="url(#back_glute_grad2)" opacity="0.3"/>
  <!-- Top roundness -->
  <ellipse cx="80" cy="110" rx="10" ry="12" fill="url(#back_glute_grad1)" opacity="0.25"/>
  <ellipse cx="120" cy="110" rx="10" ry="12" fill="url(#back_glute_grad1)" opacity="0.25"/>'''
    },

    "back_calves": {
        "content": '''  <!-- Same as front but viewed from back -->
  <path d="M 80 165 Q 72 175 72 190 Q 80 195 90 192 L 85 165 Z" fill="currentColor" opacity="0.85"/>
  <path d="M 120 165 Q 128 175 128 190 Q 120 195 110 192 L 115 165 Z" fill="currentColor" opacity="0.85"/>
  <!-- Soleus underneath -->
  <ellipse cx="85" cy="182" rx="8" ry="8" fill="currentColor" opacity="0.75"/>
  <ellipse cx="115" cy="182" rx="8" ry="8" fill="currentColor" opacity="0.75"/>
  <!-- Highlight shimmer -->
  <path d="M 82" y1="170" x2="76" y2="188" stroke="url(#back_calves_grad1)" stroke-width="2" fill="none" opacity="0.3"/>
  <path d="M 118" y1="170" x2="124" y2="188" stroke="url(#back_calves_grad1)" stroke-width="2" fill="none" opacity="0.3"/>'''
    },
}

def generate_svg(muscle_id, muscle_data):
    """Generate SVG file for a muscle."""
    svg = SVG_TEMPLATE.format(
        id=muscle_id,
        content=muscle_data["content"]
    )
    return svg

def write_asset(filename, svg_content):
    """Write SVG file to assets directory."""
    filepath = ASSETS_DIR / filename
    filepath.write_text(svg_content)
    print(f"✓ Generated {filename}")

if __name__ == "__main__":
    for muscle_id, muscle_data in MUSCLES.items():
        svg_content = generate_svg(muscle_id, muscle_data)
        write_asset(f"{muscle_id}.svg", svg_content)

    print(f"\n✓ Generated {len(MUSCLES)} muscle SVG assets!")
    print(f"  Location: {ASSETS_DIR}")
