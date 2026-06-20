import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Joy
from geometry_msgs.msg import Twist


class JoyToTwistNode(Node):
    """
    Node that converts joystick Joy messages to Twist cmd_vel messages.
    
    Subscribes to /joy topic and publishes to /cmd_vel topic.
    Supports configurable axis mapping, speed scaling, and dead zones.
    """

    def __init__(self):
        super().__init__(
            'joy_to_twist_node',
            automatically_declare_parameters_from_overrides=True
        )

        # Declare parameters with defaults
        self._declare_parameters()

        # Get parameter values
        self.axis_linear_x = int(self.get_parameter('axis_linear_x').value)
        self.axis_linear_y = int(self.get_parameter('axis_linear_y').value)
        self.axis_angular_z = int(self.get_parameter('axis_angular_z').value)
        self.max_linear_speed = float(self.get_parameter('max_linear_speed').value)
        self.max_angular_speed = float(self.get_parameter('max_angular_speed').value)
        self.dead_zone = float(self.get_parameter('dead_zone').value)
        self.joy_topic = self.get_parameter('joy_topic').get_parameter_value().string_value
        self.cmd_vel_topic = self.get_parameter('cmd_vel_topic').get_parameter_value().string_value

        # Create subscriber and publisher
        self.joy_sub = self.create_subscription(
            Joy,
            self.joy_topic,
            self.joy_callback,
            10
        )

        self.cmd_vel_pub = self.create_publisher(
            Twist,
            self.cmd_vel_topic,
            10
        )

        self.get_logger().info(f'JoyToTwist node initialized')
        self.get_logger().info(f'  Subscribing to: {self.joy_topic}')
        self.get_logger().info(f'  Publishing to: {self.cmd_vel_topic}')
        self.get_logger().info(f'  Axis mapping: linear_x={self.axis_linear_x}, '
                              f'linear_y={self.axis_linear_y}, angular_z={self.axis_angular_z}')
        self.get_logger().info(f'  Max speeds: linear={self.max_linear_speed} m/s, '
                              f'angular={self.max_angular_speed} rad/s')
        self.get_logger().info(f'  Dead zone: {self.dead_zone}')

    def _declare_parameters(self):
        """Declare parameters with default values."""
        defaults = {
            'axis_linear_x': 1,
            'axis_linear_y': 0,
            'axis_angular_z': 2,
            'max_linear_speed': 1.0,
            'max_angular_speed': 2.0,
            'dead_zone': 0.1,
            'joy_topic': '/joy',
            'cmd_vel_topic': '/cmd_vel',
        }

        for name, default in defaults.items():
            if not self.has_parameter(name):
                self.declare_parameter(name, default)

    def joy_callback(self, msg: Joy):
        """Callback for joystick messages - converts to Twist and publishes."""
        # Check if axes are available
        if (self.axis_linear_x >= len(msg.axes) or
            self.axis_linear_y >= len(msg.axes) or
            self.axis_angular_z >= len(msg.axes)):
            self.get_logger().warn_throttle(
                2.0,
                f'Axis index out of range. Received {len(msg.axes)} axes, '
                f'but need at least {max(self.axis_linear_x, self.axis_linear_y, self.axis_angular_z) + 1}'
            )
            return

        # Get joystick values
        linear_x_raw = msg.axes[self.axis_linear_x] if self.axis_linear_x < len(msg.axes) else 0.0
        linear_y_raw = msg.axes[self.axis_linear_y] if self.axis_linear_y < len(msg.axes) else 0.0
        angular_z_raw = msg.axes[self.axis_angular_z] if self.axis_angular_z < len(msg.axes) else 0.0

        # Apply dead zone
        if abs(linear_x_raw) < self.dead_zone:
            linear_x_raw = 0.0
        if abs(linear_y_raw) < self.dead_zone:
            linear_y_raw = 0.0
        if abs(angular_z_raw) < self.dead_zone:
            angular_z_raw = 0.0

        # Scale to max speeds
        vx = linear_x_raw * self.max_linear_speed
        vy = linear_y_raw * self.max_linear_speed
        omega = angular_z_raw * self.max_angular_speed

        # Create and publish Twist message
        twist_msg = Twist()
        twist_msg.linear.x = vx
        twist_msg.linear.y = vy
        twist_msg.linear.z = 0.0
        twist_msg.angular.x = 0.0
        twist_msg.angular.y = 0.0
        twist_msg.angular.z = omega

        self.cmd_vel_pub.publish(twist_msg)


def main(args=None):
    rclpy.init(args=args)
    node = JoyToTwistNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()

