class CorrectHorseBatteryStaple::Backend
  autoload :Isam,     "correct_horse_battery_staple/backend/isam"
  autoload :IsamKD,   "correct_horse_battery_staple/backend/isam_kd"
  autoload :Sqlite,   "correct_horse_battery_staple/backend/sqlite"
  autoload :Redis,    "correct_horse_battery_staple/backend/redis"
end
