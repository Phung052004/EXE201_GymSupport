using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymSupport.Repository.Models.DTOs.Exercise
{
    public class CreateExerciseDto
    {
        public string Name { get; set; }

        public string Equipment { get; set; }

        public string Difficulty { get; set; }

        public string ImageUrl { get; set; }

        public string VideoUrl { get; set; }

        public List<MuscleImpactDto> MuscleImpacts
        { get; set; } = new();
    }
}
